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
    // Allows RM0 payments even if balance is 0. Only blocks if price > balance.
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

      if (!mounted) return;
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
            colors: [Color(0xFFA500FF), Color(0xFF6A00F4)],
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
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20), 
            onPressed: () => Navigator.pop(context)
          ),
          const Text("WashSync Wallet", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _balanceCard(double balance) {
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
                  : (isPaying && widget.amountToDeduct > 0) ? Colors.red : const Color(0xFFA500FF),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isPaying 
                ? () => _handleWalletPayment(balance) 
                : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TopUpScreen())),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA500FF),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text(
              isPaying 
                ? (widget.amountToDeduct == 0 ? "CLAIM FREE WASH" : "CONFIRM PAYMENT") 
                : "RELOAD WALLET", 
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
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
              labelColor: const Color(0xFFA500FF),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFFA500FF),
              indicatorWeight: 3,
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
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No transactions yet", style: TextStyle(color: Colors.grey)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data = snapshot.data!.docs[index];
            bool isNeg = data['amount'].toString().contains('-');
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isNeg ? Colors.red : Colors.green).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isNeg ? Icons.shopping_cart_outlined : Icons.account_balance_wallet_outlined, 
                  color: isNeg ? Colors.red : Colors.green,
                  size: 20,
                ),
              ),
              title: Text(data['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(data['date'].toString().substring(0, 10)), // Show date
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
              elevation: 0,
              color: Colors.grey[50],
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey[200]!)),
              child: ListTile(
                leading: const Icon(Icons.stars, color: Colors.orange),
                title: Text(data.id, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA500FF))),
                subtitle: Text(data['description']),
              ),
            );
          },
        );
      },
    );
  }
}