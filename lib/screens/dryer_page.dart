import 'package:flutter/material.dart';
import 'payment_screen.dart';

class DryerPage extends StatelessWidget {
  const DryerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Matching the header style of your other screens
      appBar: AppBar(
        title: const Text("Select Dryer", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFB97AD9), // Your Dryer theme color
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3E5F5), Colors.white], // Light lavender gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,           // 2 boxes per row
            crossAxisSpacing: 16,        // Space between boxes
            mainAxisSpacing: 16,         // Space between rows
            childAspectRatio: 0.85,      // Adjusts the height of the boxes
          ),
          itemCount: 5,                  // 5 Dryers
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Dryer Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB97AD9).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.dry, 
                      size: 40, 
                      color: Color(0xFFB97AD9)
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Dryer ${index + 1}", 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                  const Text(
                    "RM 5.00", 
                    style: TextStyle(color: Colors.grey, fontSize: 13)
                  ),
                  const SizedBox(height: 15),
                  // Pay Button
                  SizedBox(
                    width: 100,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => const PaymentScreen())
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB97AD9),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text(
                        "PAY NOW", 
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}