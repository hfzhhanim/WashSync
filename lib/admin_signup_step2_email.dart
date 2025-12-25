import 'package:flutter/material.dart';
import 'admin_sign_in_page.dart';
import 'admin_signup_step3_password.dart';

class AdminSignUpStep2Email extends StatefulWidget {
  final String adminName;

  const AdminSignUpStep2Email({
    super.key,
    required this.adminName,
  });

  @override
  State<AdminSignUpStep2Email> createState() => _AdminSignUpStep2EmailState();
}

class _AdminSignUpStep2EmailState extends State<AdminSignUpStep2Email> {
  final TextEditingController emailController = TextEditingController();
  String errorText = "";
  bool privacyChecked = false;

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
            child: Column(
              children: [
                const SizedBox(height: 30),

                /// LOGO
                Image.asset("assets/icons/logoWashSync.png", height: 90),
                const SizedBox(height: 8),

                const Text(
                  "WashSync",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Save time. Stay fresh.",
                  style: TextStyle(color: Colors.purple),
                ),

                const SizedBox(height: 30),

                /// CARD
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// HEADER
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
                                child: const Icon(
                                  Icons.mail_outline,
                                  color: Colors.purple,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),
                          const Text(
                            "We'll use this to sign you in",
                            style: TextStyle(color: Colors.purple),
                          ),

                          const SizedBox(height: 16),

                          /// PROGRESS
                          Row(
                            children: [
                              _progress(active: true),
                              _progress(active: true),
                              _progress(active: false),
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
                            decoration: InputDecoration(
                              hintText: "you@admin.my",
                              prefixIcon: const Icon(Icons.mail_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
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

                          const SizedBox(height: 14),

                          /// PRIVACY
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.purple),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.shield_outlined,
                                  color: Colors.purple,
                                  size: 26,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        "Your privacy matters",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        "We'll never share your email. It's only used for account access and important updates.",
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// BUTTONS
                          Row(
                            children: [
                              /// 🔙 BACK BUTTON
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.purple,
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.purple.withOpacity(0.4),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
                                        SizedBox(width: 6),
                                        Text(
                                          "Back",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 14),

                              /// ➡️ NEXT BUTTON
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: _next, 
                                  child: Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF9C27FF),
                                          Color(0xFFA500FF),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.purple.withOpacity(0.45),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Next",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(width: 6),
                                        Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

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
                            builder: (_) => const AdminSignInPage(),
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

  void _next() {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      setState(() => errorText = "Email cannot be empty");
      return;
    }

    if (!email.endsWith('@admin.my')) {
      setState(() {
        errorText = "Admin email must end with @admin.my";
      });
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminSignUpStep3Password(
          adminName: widget.adminName,
          email: email,
        ),
      ),
    );
  }

  Widget _progress({required bool active}) {
    return Expanded(
      child: Container(
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: active ? Colors.purple : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
