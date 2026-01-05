import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_main_screen.dart';
import 'admin_signup_step1_name.dart';

class AdminSignInPage extends StatefulWidget {
  const AdminSignInPage({super.key});

  @override
  State<AdminSignInPage> createState() => _AdminSignInPageState();
}

class _AdminSignInPageState extends State<AdminSignInPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscure = true;
  bool loading = false;
  String error = "";

  Future<void> signIn() async {
    setState(() {
      loading = true;
      error = "";
    });

    try {
      final cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = cred.user!;
      
      if (!user.email!.endsWith('@admin.my')) {
        await FirebaseAuth.instance.signOut();
        setState(() => error = "Not an admin account");
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminMainScreen()),
      );
    } catch (e) {
      setState(() => error = "Invalid email or password");
    } finally {
      setState(() => loading = false);
    }
  }

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

        // ✅ FIX OVERFLOW
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Column(
                  children: [
                    Image.asset(
                      "assets/icons/logoWashSync.png",
                      height: 100,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "WashSync",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Save time. Stay fresh.",
                      style: TextStyle(color: Colors.purple),
                    ),

                    const SizedBox(height: 40),

                    // CARD
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 20,
                            color: Colors.black.withOpacity(0.15),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Welcome Back",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Sign in to your ADMIN account",
                            style: TextStyle(color: Colors.black54),
                          ),

                          const SizedBox(height: 30),
                          _field(
                            Icons.email_outlined,
                            emailController,
                            "you@admin.my",
                          ),
                          const SizedBox(height: 20),
                          _field(
                            Icons.lock_outline,
                            passwordController,
                            "••••••••",
                            isPassword: true,
                          ),

                          if (error.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(error,
                                style: const TextStyle(color: Colors.red)),
                          ],

                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: loading ? null : signIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFA500FF), // 💜 your colour
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 6,
                                shadowColor: Colors.purple.withOpacity(0.4),
                              ),
                              child: loading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      "Sign In",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Don't have an account? "),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AdminSignUpStep1Name(),
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    IconData icon,
    TextEditingController controller,
    String hint, {
    bool isPassword = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.purple.shade200),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: isPassword ? obscure : false,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
              ),
            ),
          ),
          if (isPassword)
            IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () => setState(() => obscure = !obscure),
            ),
        ],
      ),
    );
  }
}
