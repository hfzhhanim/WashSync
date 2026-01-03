import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'online_banking_popup.dart';
import 'tng_popup.dart';
import 'wallet_page.dart';
import 'success_popup.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int selectedMethod = -1; // 0=Wallet, 1=Online Banking, 2=TNG
  String? selectedBank;
  final User? user = FirebaseAuth.instance.currentUser;

  String promoCode = '';
  double promoDiscountValue = 0.0;
  String? appliedCode; 
  final double basePrice = 5.00;

  final List<String> banks = [
    'Maybank', 'CIMB Bank', 'Public Bank', 'RHB Bank', 'Hong Leong Bank',
  ];

  double get totalPrice {
    final total = basePrice - promoDiscountValue;
    return total < 0 ? 0 : total;
  }

  Widget _walletBalanceDisplay() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text("Balance: RM 0.00", style: TextStyle(fontSize: 12, color: Colors.grey));
        }
        var data = snapshot.data!.data() as Map<String, dynamic>;
        double currentBalance = (data['balance'] ?? 0.0).toDouble();
        bool insufficient = currentBalance < totalPrice;

        return Text(
          "Balance: RM ${currentBalance.toStringAsFixed(2)}",
          style: TextStyle(
            fontSize: 12, 
            fontWeight: FontWeight.bold,
            color: insufficient ? Colors.red : Colors.grey[600],
          ),
        );
      },
    );
  }

  Future<void> _applyPromo() async {
    if (promoCode.isEmpty) return;
    String code = promoCode.trim().toUpperCase();

    try {
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(user?.uid).get();
<<<<<<< HEAD
      List usedPromos = (userDoc.data())?['usedPromos'] ?? [];
=======
      List usedPromos = (userDoc.data() as Map<String, dynamic>?)?['usedPromos'] ?? [];
>>>>>>> 3388b30be0a1c74806ad5c57fb8aa22408713e17

      if (usedPromos.contains(code)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Promo already used!"), backgroundColor: Colors.orange),
        );
        return;
      }

      var promoDoc = await FirebaseFirestore.instance.collection('promocodes').doc(code).get();

      if (promoDoc.exists) {
        bool active = promoDoc['isActive'] ?? false;
        if (active) {
          setState(() {
            promoDiscountValue = (promoDoc['discount'] ?? 0.0).toDouble();
            appliedCode = code; 
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Promo Applied! 🎉"), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Code Expired"), backgroundColor: Colors.red),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid Code"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error checking promo")));
    }
  }

  Future<void> processPayment() async {
    if (selectedMethod == -1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a payment method")));
      return;
    }

    bool? success;

    if (selectedMethod == 0) {
      success = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => WalletPage(amountToDeduct: totalPrice, promoUsed: appliedCode),
        ),
      );
    } else if (selectedMethod == 1) {
      if (selectedBank == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a bank")));
        return;
      }
      success = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => OnlineBankingPopup(bankName: selectedBank!, amount: totalPrice),
      );
    } else if (selectedMethod == 2) {
      success = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => TngPopup(amount: totalPrice),
      );
    }

    if (success == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => SuccessPopup(
          amount: totalPrice,
          paymentMethod: _paymentMethodName(),
          onOk: () => Navigator.popUntil(context, (route) => route.isFirst),
        ),
      );
    }
  }

  String _paymentMethodName() {
    switch (selectedMethod) {
      case 0: return "WashSync Wallet";
      case 1: return "Online Banking ($selectedBank)";
      case 2: return "Touch ‘n Go eWallet";
      default: return "Payment";
    }
  }

  Widget paymentCard({required int index, required String title, required IconData icon, required Color iconColor, Widget? extra}) {
    final selected = selectedMethod == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMethod = index;
          if (index != 0) {
            promoCode = '';
            promoDiscountValue = 0.0;
            appliedCode = null;
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? const Color(0xFFA500FF) : Colors.grey[200]!, width: 2),
          boxShadow: [if (selected) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (index == 0) _walletBalanceDisplay(),
                    ],
                  ),
                ),
                if (selected) const Icon(Icons.check_circle, color: Color(0xFFA500FF)),
              ],
            ),
            if (extra != null) extra,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFA500FF), Color(0xFF6A00F4)]),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                ),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
                    const SizedBox(width: 8),
                    const Text("Checkout", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Select Payment Method", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    paymentCard(index: 0, title: "WashSync Wallet", icon: Icons.account_balance_wallet_rounded, iconColor: const Color(0xFFA500FF)),
                    paymentCard(
                      index: 1, title: "Online Banking", icon: Icons.account_balance_rounded, iconColor: Colors.blueAccent,
                      extra: selectedMethod == 1 ? DropdownButtonFormField<String>(
<<<<<<< HEAD
                        initialValue: selectedBank, hint: const Text("Choose Bank"),
=======
                        value: selectedBank, hint: const Text("Choose Bank"),
>>>>>>> 3388b30be0a1c74806ad5c57fb8aa22408713e17
                        items: banks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                        onChanged: (v) => setState(() => selectedBank = v),
                      ) : null
                    ),
                    paymentCard(index: 2, title: "TNG eWallet", icon: Icons.qr_code_scanner_rounded, iconColor: Colors.blue),
                    if (selectedMethod == 0) ...[
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: TextField(decoration: const InputDecoration(hintText: "Promo Code"), onChanged: (v) => promoCode = v)),
                        const SizedBox(width: 10),
                        ElevatedButton(onPressed: _applyPromo, child: const Text("Apply"))
                      ]),
                    ],
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: const Color(0xFFF8F3FF), borderRadius: BorderRadius.circular(20)),
                      child: Column(children: [
                        summaryRow("Base Price", basePrice),
                        if (promoDiscountValue > 0) summaryRow("Discount", -promoDiscountValue, color: Colors.green),
                        const Divider(),
                        summaryRow("Total", totalPrice, bold: true),
                      ]),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: processPayment,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA500FF), padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        child: Text("Pay RM ${totalPrice.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget summaryRow(String label, double value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: bold ? 18 : 14, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text("RM ${value.abs().toStringAsFixed(2)}", style: TextStyle(fontSize: bold ? 18 : 14, fontWeight: bold ? FontWeight.bold : FontWeight.w600, color: color ?? (bold ? const Color(0xFFA500FF) : Colors.black87))),
        ],
      ),
    );
  }
}