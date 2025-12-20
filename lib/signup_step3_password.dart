import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sign_in_page.dart';

class SignUpStep3Password extends StatefulWidget {
  final String email;
  final String username;

  const SignUpStep3Password({
    super.key,
    required this.email,
    required this.username,
  });

  @override
  State<SignUpStep3Password> createState() => _SignUpStep3PasswordState();
}

class _SignUpStep3PasswordState extends State<SignUpStep3Password> {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  String errorText = "";
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  bool get lengthOk => passwordController.text.length >= 6;
  bool get match =>
      passwordController.text == confirmController.text &&
      passwordController.text.isNotEmpty;

  void validate() {
    if (!lengthOk) {
      errorText = "Password must be at least 6 characters";
    } else if (!match) {
      errorText = "Passwords do not match";
    } else {
      errorText = "";
    }
    setState(() {});
  }

  /// ✅ REAL FIREBASE SIGN UP (FIXED)
  Future<void> createAccount() async {
    validate();
    if (errorText.isNotEmpty) return;

    setState(() => isLoading = true);

    try {
      /// 1️⃣ CREATE AUTH ACCOUNT
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: widget.email,
        password: passwordController.text.trim(),
      );

      await userCredential.user!.sendEmailVerification();

      final uid = userCredential.user!.uid;

      /// 2️⃣ CREATE FIRESTORE USER DOCUMENT
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'username': widget.username,
        'email': widget.email,
        'totalUses': 0,
        'balance': 0,
        'vouchers': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      /// 3️⃣ SUCCESS DIALOG
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _SuccessDialog(),
      );

      await Future.delayed(const Duration(seconds: 2));

      /// 4️⃣ GO TO SIGN IN
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => SignInPage()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorText = e.message ?? "Authentication failed";
      });
    } catch (e) {
      setState(() {
        errorText = "Something went wrong. Try again.";
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/backgroundColour.png"),
            fit: BoxFit.cover,
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
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
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
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// HEADER
                      const Text(
                        "Create a password",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text("Password"),
                      const SizedBox(height: 6),
                      TextField(
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        onChanged: (_) => validate(),
                        decoration: InputDecoration(
                          hintText: "••••••••",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text("Confirm Password"),
                      const SizedBox(height: 6),
                      TextField(
                        controller: confirmController,
                        obscureText: _obscureConfirm,
                        onChanged: (_) => validate(),
                        decoration: InputDecoration(
                          hintText: "••••••••",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirm = !_obscureConfirm;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// RULES
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.purple),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            _rule("At least 6 characters", lengthOk),
                            _rule("Passwords match", match),
                          ],
                        ),
                      ),

                      if (errorText.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          errorText,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],

                      const SizedBox(height: 20),

                      /// CREATE BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : createAccount,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA500FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  "Create Account",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

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

  /// InputDecoration _inputDecoration() {
  ///  return InputDecoration(
  ///      hintText: "••••••••",
  ///    prefixIcon: const Icon(Icons.lock_outline),
  ///    border: OutlineInputBorder(
  ///      borderRadius: BorderRadius.circular(10),
  ///    ),
  ///  );
  ///} 

  Widget _rule(String text, bool ok) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.radio_button_unchecked,
          color: ok ? Colors.purple : Colors.grey,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.check_circle,
              color: Colors.purple,
              size: 64,
            ),
            SizedBox(height: 12),
            Text(
              "Account Created!",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Please verify your student email\nbefore signing in.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}