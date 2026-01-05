import 'package:flutter/material.dart';
import 'admin_sign_in_page.dart';
import 'admin_signup_step2_email.dart';

class AdminSignUpStep1Name extends StatefulWidget {
  const AdminSignUpStep1Name({super.key});

  @override
  State<AdminSignUpStep1Name> createState() => _AdminSignUpStep1NameState();
}

class _AdminSignUpStep1NameState extends State<AdminSignUpStep1Name> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();

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
            child: Column(
              children: [
                const SizedBox(height: 30),

                /// LOGO
                Image.asset(
                  "assets/icons/logoWashSync.png",
                  height: 90,
                ),
                const SizedBox(height: 8),

                const Text(
                  "WashSync",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  "Save time. Stay fresh.",
                  style: TextStyle(color: Colors.purple),
                ),

                const SizedBox(height: 30),

                /// 🔒 CARD (SAME WIDTH AS STEP 2 & 3)
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
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
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
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.person_outline,
                                  color: Colors.purple,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          const Text(
                            "Let’s start with your name",
                            style: TextStyle(color: Colors.purple),
                          ),

                          const SizedBox(height: 16),

                          /// PROGRESS BAR
                          Row(
                            children: [
                              _progress(active: true),
                              _progress(active: false),
                              _progress(active: false),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Center(
                            child: Text(
                              "Step 1 of 3",
                              style: TextStyle(color: Colors.purple),
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// FIRST NAME
                          const Text("First Name"),
                          const SizedBox(height: 6),
                          TextField(
                            controller: firstNameController,
                            decoration: InputDecoration(
                              hintText: "John",
                              prefixIcon:
                                  const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          /// LAST NAME
                          const Text("Last Name"),
                          const SizedBox(height: 6),
                          TextField(
                            controller: lastNameController,
                            decoration: InputDecoration(
                              hintText: "Doe",
                              prefixIcon:
                                  const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
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

                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.purple),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.help_outline,
                                    color: Colors.purple,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Why we need this",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "We'll use your name to personalize your laundry service experience.",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.purple,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// NEXT BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: GestureDetector(
                              onTap: _next,
                              child: Container(
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
                                      blurRadius: 12,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Next",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
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
    if (firstNameController.text.trim().isEmpty ||
        lastNameController.text.trim().isEmpty) {
      setState(() {
        errorText = "Please enter your full name";
      });
      return;
    }

    final username =
        "${firstNameController.text.trim()} ${lastNameController.text.trim()}";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminSignUpStep2Email(
          adminName: username,
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
