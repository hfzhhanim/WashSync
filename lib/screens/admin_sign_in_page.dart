import 'package:flutter/material.dart';

class AdminSignInPage extends StatelessWidget {
  const AdminSignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Sign In"),
      ),
      body: const Center(
        child: Text(
          "Admin Sign In Page\n(UI coming soon)",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
