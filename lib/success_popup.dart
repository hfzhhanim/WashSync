import 'package:flutter/material.dart';

class SuccessPopup extends StatelessWidget {
  final double amount;
  final String paymentMethod; // This was likely missing or named differently
  final VoidCallback onOk;

  const SuccessPopup({
    super.key,
    required this.amount,
    required this.paymentMethod, // Added here
    required this.onOk,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, size: 80, color: Colors.green),
            ),
            const SizedBox(height: 24),
            const Text(
              "Payment Successful!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "RM ${amount.toStringAsFixed(2)} has been processed via $paymentMethod.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close Popup
                  onOk(); // Return to Home
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8A3FFC),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text(
                  "Back to Home",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}