import 'package:flutter/material.dart';

class SuccessPopup extends StatelessWidget {
  final double amount;
  final String paymentMethod;
  final VoidCallback onOk;

  const SuccessPopup({
    super.key,
    required this.amount,
    required this.paymentMethod,
    required this.onOk,
  });

  @override
  Widget build(BuildContext context) {
    // Check if it's a free wash from a promo
    final bool isFree = amount <= 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon with soft pulse effect look
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded, 
                size: 90, 
                color: Colors.green
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isFree ? "Free Wash Applied!" : "Payment Successful!",
              style: const TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold,
                color: Colors.black87
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isFree 
                ? "Your promo code has been used successfully. Enjoy your wash!"
                : "RM ${amount.toStringAsFixed(2)} has been processed via $paymentMethod.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600], 
                fontSize: 15,
                height: 1.5
              ),
            ),
            const SizedBox(height: 32),
            // Primary Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                  onOk(); // Execute the home redirection
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8A3FFC), // Match your theme purple
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "BACK TO HOME",
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}