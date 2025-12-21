import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'topup_screen.dart';

class WalletPage extends StatefulWidget {
  final double amountToDeduct; 
  final String? promoUsed; 

  const WalletPage({
    super.key, 
    required this.amountToDeduct, 
    this.promoUsed, 
  });

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // ================= DEDUCTION & PROMO BURN LOGIC =================
  Future<void> _handleWalletPayment(double currentBalance) async {
    // Only block if they actually owe money they don't have
    if (widget.amountToDeduct > 0 && currentBalance < widget.amountToDeduct) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insufficient Balance!"), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user?.uid);

      await FirebaseFirestore.instance.runTransaction((tx) async {
        Map<String, dynamic> updates = {
          'balance': currentBalance - widget.amountToDeduct,
          'totalUses': FieldValue.increment(1), 
        };

        if (widget.promoUsed != null) {
          updates['usedPromos'] = FieldValue.arrayUnion([widget.promoUsed]);
        }

        tx.update(userRef, updates);

        tx.set(userRef.collection('transactions').doc(), {
          'title': widget.amountToDeduct == 0 
              ? 'Free Laundry Service' 
              : 'Laundry Service Payment',
          'amount': '-RM${widget.amountToDeduct.toStringAsFixed(2)}',
          'date': DateTime.now().toIso8601String(),
        });
      });

      Navigator.pop(context, true); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment Failed: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD8B4F8), Color(0xFFC084FC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));
              
              var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
              double balance = (userData['balance'] ?? 0).toDouble();

              return Column(
                children: [
                  _header(context),
                  _balanceCard(balance),
                  _tabsSection(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
          const Text("WashSync Wallet", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _balanceCard(double balance) {
    // Logic: If amountToDeduct is >= 0, we are in payment mode. 
    // If it's -1.0 (from HomePage), we are in viewing mode.
    bool isPaying = widget.amountToDeduct >= 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24), 
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        children: [
          Text(isPaying ? "Payment Summary" : "Available Balance", style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            isPaying ? "RM ${widget.amountToDeduct.toStringAsFixed(2)}" : "RM ${balance.toStringAsFixed(2)}", 
            style: TextStyle(
              fontSize: 36, 
              fontWeight: FontWeight.bold, 
              color: (isPaying && widget.amountToDeduct == 0) 
                  ? Colors.green 
                  : (isPaying && widget.amountToDeduct > 0) ? Colors.red : const Color(0xFF8A3FFC),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isPaying 
                ? () => _handleWalletPayment(balance) 
                : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TopUpScreen())),
            style: ElevatedButton.styleFrom(
              backgroundColor: isPaying 
                  ? (widget.amountToDeduct == 0 ? Colors.green : const Color(0xFF8A3FFC)) 
                  : const Color(0xFF8A3FFC),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              isPaying 
                ? (widget.amountToDeduct == 0 ? "CLAIM FREE WASH" : "CONFIRM PAYMENT") 
                : "RELOAD WALLET", 
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  Widget _tabsSection() {
    return Expanded(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF8A3FFC),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF8A3FFC),
              tabs: const [Tab(text: "History"), Tab(text: "Benefits")],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_historyList(), _benefitsList()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('transactions')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data = snapshot.data!.docs[index];
            bool isNeg = data['amount'].toString().contains('-');
            return ListTile(
              leading: Icon(
                isNeg ? Icons.remove_circle_outline : Icons.add_circle_outline, 
                color: isNeg ? Colors.red : Colors.green,
              ),
              title: Text(data['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text(
                data['amount'], 
                style: TextStyle(
                  color: isNeg ? Colors.red : Colors.green, 
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _benefitsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('promocodes')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data = snapshot.data!.docs[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: const Icon(Icons.card_giftcard, color: Colors.orange),
                title: Text(data.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(data['description']),
              ),
            );
          },
        );
      },
    );
  }
}