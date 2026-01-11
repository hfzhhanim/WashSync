import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_step1_name.dart';
import 'home_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _obscurePassword = true;
  bool isLoading = false;
  String errorText = "";

  Future<void> signIn() async {
    setState(() {
      isLoading = true;
      errorText = "";
    });

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user!;

      if (!user.emailVerified) {
        await _auth.signOut();
        setState(() {
          errorText = "Please verify your student email before signing in.";
        });
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          errorText = "No account found for this email";
        } else if (e.code == 'wrong-password') {
          errorText = "Incorrect password";
        } else {
          errorText = e.message ?? "Login failed";
        }
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _handleForgotPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email first")),
      );
      return;
    }

    await _auth.sendPasswordResetEmail(email: email);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Password reset email sent")),
    );
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFB388FF), Color(0xFFE1BEE7)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),

                        /// LOGO
                        Image.asset(
                          "assets/icons/logoWashSync.png",
                          height: 150,
                        ),

                        const SizedBox(height: 6),

                        const Text(
                          "WashSync",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const Text(
                          "Save time. Stay fresh.",
                          style: TextStyle(color: Colors.purple),
                        ),

                        const SizedBox(height: 30),

                        /// 👇 CENTER CARD + TABLET WIDTH CONTROL
                        Center(
                          child: ConstrainedBox(
                            constraints:
                                const BoxConstraints(maxWidth: 420),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Center(
                                    child: Text(
                                      "Welcome Back",
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 8),
                                  const Center(
                                    child: Text(
                                      "Sign in to your WashSync account",
                                    ),
                                  ),

                                  const SizedBox(height: 30),

                                  const Text("Email"),
                                  const SizedBox(height: 6),
                                  _inputField(
                                    icon: Icons.mail_outline,
                                    controller: emailController,
                                    hint: "you@student.usm.my",
                                    obscure: false,
                                  ),

                                  const SizedBox(height: 20),

                                  const Text("Password"),
                                  const SizedBox(height: 6),
                                  _inputField(
                                    icon: Icons.lock_outline,
                                    controller: passwordController,
                                    hint: "••••••••",
                                    obscure: true,
                                    isPassword: true,
                                  ),

                                  const SizedBox(height: 6),

                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: GestureDetector(
                                      onTap: _handleForgotPassword,
                                      child: const Text(
                                        "Forgot Password",
                                        style: TextStyle(
                                          color: Colors.purpleAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),

                                  if (errorText.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      errorText,
                                      style: const TextStyle(
                                          color: Colors.red),
                                    ),
                                  ],

                                  const SizedBox(height: 30),

                                  SizedBox(
                                    width: double.infinity,
                                    height: 45,
                                    child: ElevatedButton(
                                      style:
                                          ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFA500FF),
                                      ),
                                      onPressed:
                                          isLoading ? null : signIn,
                                      child: isLoading
                                          ? const CircularProgressIndicator(
                                              color: Colors.white,
                                            )
                                          : const Text(
                                              "Sign In",
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                          "Don’t have an account? "),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const SignUpStep1Name(),
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          "Sign up",
                                          style: TextStyle(
                                            color: Colors.purple,
                                            fontWeight: FontWeight.bold,
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

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }


  Widget _inputField({
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    bool isPassword = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.purple.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: isPassword ? _obscurePassword : obscure,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
              ),
            ),
          ),
          if (isPassword)
            IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
        ],
      ),
    );
  }
}
