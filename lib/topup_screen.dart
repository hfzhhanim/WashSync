import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'online_banking_popup.dart';
import 'tng_popup.dart';
import 'success_popup.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  int selectedMethod = -1; // 1=Online Banking, 2=TNG
  String? selectedBank;
  final TextEditingController _amountController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;

  final List<String> banks = [
    'Maybank', 'CIMB Bank', 'Public Bank', 'RHB Bank', 'Hong Leong Bank',
  ];

  // Helper to get double value from text
  double get reloadAmount {
    return double.tryParse(_amountController.text) ?? 0.0;
  }

  // ================= RELOAD LOGIC =================
  Future<void> _processReload() async {
    if (reloadAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a valid amount")));
      return;
    }

    bool? success = false;

    if (selectedMethod == 1) {
      if (selectedBank == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a bank")));
        return;
      }
      success = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => OnlineBankingPopup(bankName: selectedBank!, amount: reloadAmount),
      );
    } else if (selectedMethod == 2) {
      success = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => TngPopup(amount: reloadAmount),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a payment method")));
      return;
    }

    if (success == true) {
      // UPDATE FIREBASE BALANCE
      try {
        await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
          'balance': FieldValue.increment(reloadAmount),
        });

        // ADD TO TRANSACTION HISTORY
        await FirebaseFirestore.instance.collection('users').doc(user?.uid).collection('transactions').add({
          'title': 'Wallet Reload',
          'amount': '+RM${reloadAmount.toStringAsFixed(2)}',
          'date': DateTime.now().toIso8601String(),
        });

        // SHOW SUCCESS POPUP
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => SuccessPopup(
            amount: reloadAmount,
            paymentMethod: selectedMethod == 1 ? "Online Banking ($selectedBank)" : "TNG eWallet",
            onOk: () => Navigator.pop(context), // Go back to Wallet Page
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Update Failed")));
      }
    }
  }

  // ================= SHARED UI COMPONENT =================
  Widget paymentCard({
    required int index,
    required String title,
    required IconData icon,
    required Color iconColor,
    Widget? extra,
  }) {
    final selected = selectedMethod == index;
    return GestureDetector(
      onTap: () => setState(() => selectedMethod = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFA500FF) : Colors.grey[200]!,
            width: 2,
          ),
          boxShadow: [
            if (selected) BoxShadow(color: const Color(0xFFA500FF).withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
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
              // PURPLE HEADER (Matches Payment Screen)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFA500FF), Color(0xFF6A00F4)]),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text("Reload Wallet", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

              // AMOUNT INPUT
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Text("Enter Amount", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFA500FF)),
                  decoration: InputDecoration(
                    prefixText: "RM ",
                    prefixStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFA500FF)),
                    hintText: "0.00",
                    filled: true,
                    fillColor: const Color(0xFFF8F3FF),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Text("Select Top-Up Method", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),

              // RELOAD METHODS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    paymentCard(
                      index: 1,
                      title: "Online Banking",
                      icon: Icons.account_balance_rounded,
                      iconColor: Colors.blueAccent,
                      extra: selectedMethod == 1
                          ? Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                value: selectedBank,
                                hint: const Text("Choose Bank"),
                                items: banks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                                onChanged: (v) => setState(() => selectedBank = v),
                              ),
                            )
                          : null,
                    ),
                    paymentCard(
                      index: 2,
                      title: "TNG eWallet",
                      icon: Icons.qr_code_scanner_rounded,
                      iconColor: Colors.blue,
                    ),
                  ],
                ),
              ),

              // RELOAD BUTTON
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 40),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _processReload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA500FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: const Text("RELOAD NOW", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}