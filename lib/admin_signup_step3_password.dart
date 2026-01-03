import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_sign_in_page.dart';

class AdminSignUpStep3Password extends StatefulWidget {
  final String adminName;
  final String email;

  const AdminSignUpStep3Password({
    super.key,
    required this.adminName,
    required this.email,
  });

  @override
  State<AdminSignUpStep3Password> createState() =>
      _AdminSignUpStep3PasswordState();
}

class _AdminSignUpStep3PasswordState
    extends State<AdminSignUpStep3Password> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  bool obscurePass = true;
  bool obscureConfirm = true;
  bool isLoading = false;
  String errorText = "";

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

  Future<void> createAdminAccount() async {
    validate();
    if (errorText.isNotEmpty) return;

    setState(() => isLoading = true);

    try {
      /// 🔐 CREATE AUTH ACCOUNT
      UserCredential credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: widget.email,
        password: passwordController.text.trim(),
      );

      await credential.user!.sendEmailVerification();

      /// 🧾 SAVE ADMIN DATA
      await FirebaseFirestore.instance
          .collection('admins')
          .doc(credential.user!.uid)
          .set({
        'username': widget.adminName,
        'email': widget.email,
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      });

      /// ✅ SUCCESS
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _SuccessDialog(),
      );

      await Future.delayed(const Duration(seconds: 2));

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdminSignInPage()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorText = e.message ?? "Authentication failed";
      });
    } catch (e) {
      setState(() {
        errorText = e.toString();
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 30),

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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// LEFT TEXT
<<<<<<< HEAD
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
=======
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
>>>>>>> 3388b30be0a1c74806ad5c57fb8aa22408713e17
                                    Text(
                                      "Create an account",
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Create a strong password",
                                      style: TextStyle(
                                        color: Colors.purple,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              /// RIGHT LOCK ICON
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
<<<<<<< HEAD
                                  color: const Color(0xFFE9D5FF),
=======
                                  color: Color(0xFFE9D5FF),
>>>>>>> 3388b30be0a1c74806ad5c57fb8aa22408713e17
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.lock_outline,
                                  color: Colors.purple,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          /// PASSWORD
                          const Text("Password"),
                          const SizedBox(height: 6),
                          TextField(
                            controller: passwordController,
                            obscureText: obscurePass,
                            onChanged: (_) => validate(),
                            decoration: InputDecoration(
                              hintText: "••••••••",
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscurePass
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    obscurePass = !obscurePass;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          /// CONFIRM
                          const Text("Confirm Password"),
                          const SizedBox(height: 6),
                          TextField(
                            controller: confirmController,
                            obscureText: obscureConfirm,
                            onChanged: (_) => validate(),
                            decoration: InputDecoration(
                              hintText: "••••••••",
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureConfirm
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    obscureConfirm = !obscureConfirm;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          /// RULES
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.purple),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                _rule("At least 6 characters", lengthOk),
                                _rule("Passwords match", match),
                              ],
                            ),
                          ),

                          if (errorText.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              errorText,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],

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

                              Expanded(
                                child: GestureDetector(
                                  onTap: isLoading ? null : createAdminAccount,
                                  child: Container(
                                    height: 52,
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
                                    child: Center(
                                      child: isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.check, color: Colors.white, size: 20),
                                                SizedBox(width: 8),
                                                Text(
                                                  "Create Account",
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
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
<<<<<<< HEAD
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
=======
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
>>>>>>> 3388b30be0a1c74806ad5c57fb8aa22408713e17
            Icon(Icons.check_circle, color: Colors.purple, size: 64),
            SizedBox(height: 12),
            Text(
              "Admin Account Created!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
