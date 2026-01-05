import 'package:flutter/material.dart';
import 'sign_in_page.dart';
import 'signup_step3_password.dart';

class SignUpStep2Email extends StatefulWidget {
  final String username; // 🔥 received from Step 1

  const SignUpStep2Email({
    super.key,
    required this.username,
  });

  @override
  State<SignUpStep2Email> createState() => _SignUpStep2EmailState();
}

class _SignUpStep2EmailState extends State<SignUpStep2Email> {
  final emailController = TextEditingController();

  String errorText = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xFFB388FF), Color(0xFFE1BEE7)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 30),

                Image.asset("assets/icons/logoWashSync.png", height: 90),
                const SizedBox(height: 10),

                const Text(
                  "WashSync",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  "Save time. Stay fresh.",
                  style: TextStyle(color: Colors.purple),
                ),

                const SizedBox(height: 30),

                /// CARD
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// TITLE
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Create an account",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.email,
                                color: Colors.purple),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        "We'll use this to sign you in",
                        style: TextStyle(color: Colors.purple),
                      ),

                      const SizedBox(height: 16),

                      /// PROGRESS
                      Row(
                        children: [
                          _progressBar(active: true),
                          _progressBar(active: true),
                          _progressBar(active: false),
                        ],
                      ),

                      const SizedBox(height: 6),
                      const Center(
                        child: Text(
                          "Step 2 of 3",
                          style: TextStyle(color: Colors.purple),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// EMAIL FIELD
                      const Text("Email Address"),
                      const SizedBox(height: 6),

                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: "you@student.usm.my",
                          prefixIcon:
                              const Icon(Icons.mail_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      if (errorText.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          errorText,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],


                      const SizedBox(height: 12),


                      /// PRIVACY INFO
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.purple),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                 Icon(Icons.shield_outlined, color: Colors.purple),
                                 SizedBox(width: 8),
                                Text(
                                  "Your privacy matters",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                ),
                              ],
                            ),


                            SizedBox(height: 6),


                            Text(
                              "We’ll never share your email. It's only used for account access and important updates.",
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),


                      const SizedBox(height: 20),

                      /// BUTTONS
                      Row(
                        children: [
                          /// BACK
                          Expanded(
                            child: _button(
                              text: "Back",
                              icon: Icons.arrow_back,
                              onTap: () => Navigator.pop(context),
                            ),
                          ),

                          const SizedBox(width: 14),

                          /// NEXT
                          Expanded(
                            child: _button(
                              text: "Next",
                              icon: Icons.arrow_forward,
                              iconFirst: false,
                              onTap: () {
                                final email = emailController.text.trim();

                                if (email.isEmpty) {
                                  setState(() => errorText = "Email cannot be empty");
                                  return;
                                }

                                if (!isValidStudentEmail(email)) {
                                  setState(() => errorText =
                                      "Please use a valid USM student email (@student.usm.my)");
                                  return;
                                }

                                setState(() => errorText = "");

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SignUpStep3Password(
                                      email: email,
                                      username: widget.username,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// SIGN IN
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignInPage(),
                          ),
                          (_) => false,
                        );
                      },
                      child: const Text(
                        "Sign in",
                        style: TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool isValidStudentEmail(String email) {
    final regex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@student\.usm\.my$');
    return regex.hasMatch(email);
  }


  Widget _progressBar({required bool active}) {
    return Expanded(
      child: Container(
        height: 6,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: active ? Colors.purple : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _button({
    required String text,
    IconData? icon,
    bool iconFirst = true,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFA500FF),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null && iconFirst) ...[
              Icon(icon, color: Colors.white),
              const SizedBox(width: 6),
            ],
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (icon != null && !iconFirst) ...[
              const SizedBox(width: 6),
              Icon(icon, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }
}
