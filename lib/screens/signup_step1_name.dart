import 'package:flutter/material.dart';
import 'sign_in_page.dart';
import 'signup_step2_email.dart';

class SignUpStep1Name extends StatefulWidget {
  const SignUpStep1Name({super.key});

  @override
  State<SignUpStep1Name> createState() => _SignUpStep1NameState();
}

class _SignUpStep1NameState extends State<SignUpStep1Name> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/backgroundColour.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 30),

                Image.asset(
                  "assets/icons/logoWashSync.png",
                  width: 100,
                ),

                const SizedBox(height: 10),

                const Text(
                  "WashSync",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const Text(
                  "Save time. Stay fresh.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.purple,
                  ),
                ),

                const SizedBox(height: 30),

                /// CARD
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 4),
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
                            child: const Icon(
                              Icons.person,
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

                      /// PROGRESS
                      Row(
                        children: [
                          _progressBar(active: true),
                          _progressBar(),
                          _progressBar(),
                        ],
                      ),

                      const SizedBox(height: 8),

                      const Center(
                        child: Text(
                          "Step 1 of 3",
                          style: TextStyle(color: Colors.purple),
                        ),
                      ),

                      const SizedBox(height: 20),

                      _inputField(
                        label: "First Name",
                        hint: "John",
                        controller: firstNameController,
                      ),

                      const SizedBox(height: 12),

                      _inputField(
                        label: "Last Name",
                        hint: "Doe",
                        controller: lastNameController,
                      ),

                      const SizedBox(height: 12),

                      // Info box
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
                                Icon(
                                  Icons.help_outline,
                                  color: Colors.purple,
                                  size: 20,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  "Why we need this",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                ),
                              ],
                            ),


                            SizedBox(height: 6),


                            Text(
                              "We’ll use your name to personalize your laundry service experience.",
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),


                      const SizedBox(height: 20),

                      /// NEXT BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA500FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            if (firstNameController.text.isEmpty ||
                                lastNameController.text.isEmpty) {
                              return;
                            }

                            final String username =
                                "${firstNameController.text.trim()} ${lastNameController.text.trim()}";

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SignUpStep2Email(
                                  username: username,
                                ),
                              ),
                            );
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Next",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, color: Colors.white),
                            ],
                          ),
                        ),
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

  Widget _progressBar({bool active = false}) {
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

  Widget _inputField({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}
