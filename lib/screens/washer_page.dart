import 'package:flutter/material.dart';
import 'payment_screen.dart';

class WasherPage extends StatelessWidget {
  const WasherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Washer"), backgroundColor: Colors.purple),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.8),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_laundry_service, size: 50, color: Colors.purple),
                const SizedBox(height: 10),
                Text("Washer ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
                const Text("RM 5.00", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentScreen())),
                  child: const Text("PAY NOW"),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}