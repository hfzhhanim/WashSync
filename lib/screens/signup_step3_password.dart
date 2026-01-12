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

  Future<void> createAccount() async {
    validate();
    if (errorText.isNotEmpty) return;

    setState(() => isLoading = true);

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: widget.email,
        password: passwordController.text.trim(),
      );

      await userCredential.user!.sendEmailVerification();

      final uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'username': widget.username,
        'email': widget.email,
        'totalUses': 0,
        'balance': 0,
        'vouchers': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _SuccessDialog(),
      );

      await Future.delayed(const Duration(seconds: 2));

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SignInPage()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorText = e.message ?? "Authentication failed";
      });
    } catch (_) {
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
        gradient: LinearGradient(
          colors: [Color(0xFFB388FF), Color(0xFFE1BEE7)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 30),

                        Image.asset(
                          "assets/icons/logoWashSync.png",
                          height: 90,
                        ),
                        const SizedBox(height: 10),

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
                              Row(
                                children: [
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Create a password",
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          "Create a strong password",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFFA500FF),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Color(0xFFF3E8FF),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.lock_outline,
                                      color: Color(0xFFA500FF),
                                      size: 26,
                                    ),
                                  ),
                                ],
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
                                  prefixIcon:
                                      const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword =
                                            !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
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
                                  prefixIcon:
                                      const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirm =
                                            !_obscureConfirm;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              /// RULES
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.purple),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    _rule(
                                        "At least 6 characters",
                                        lengthOk),
                                    _rule("Passwords match", match),
                                  ],
                                ),
                              ),

                              if (errorText.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  errorText,
                                  style: const TextStyle(
                                      color: Colors.red),
                                ),
                              ],

                              const SizedBox(height: 20),

                              /// BUTTONS
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 55,
                                      child: ElevatedButton.icon(
                                        onPressed: () => Navigator.pop(context),
                                        icon: const Icon(
                                          Icons.arrow_back_ios_new,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        label: const Text(
                                          "Back",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFA500FF),
                                          foregroundColor: Colors.white, 
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: SizedBox(
                                      height: 55,
                                      child: ElevatedButton.icon(
                                        onPressed: isLoading ? null : createAccount,
                                        icon: isLoading
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Icon(Icons.check, color: Colors.white),
                                        label: const Text(
                                          "Create Account",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFA500FF),
                                          foregroundColor: Colors.white, 
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Already have an account? "),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const SignInPage()),
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

                        const SizedBox(height: 20),
                      ],
                    ),
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

  Widget _rule(String text, bool ok) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.circle_outlined,
          color: ok ? Colors.purple : Colors.grey,
          size: 20, 
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
        padding: const EdgeInsets.all(22),
        margin: const EdgeInsets.symmetric(horizontal: 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.check_circle,
              color: Colors.purple,
              size: 48, 
            ),
            SizedBox(height: 14),

            Text(
              "Account created",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                decoration: TextDecoration.none,
              ),
            ),

            SizedBox(height: 8),

            Text(
              "Please verify your student email before signing in.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.4,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
