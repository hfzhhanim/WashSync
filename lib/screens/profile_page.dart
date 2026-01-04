import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  final picker = ImagePicker();

  bool _isEditingName = false;

  final TextEditingController _usernameController = TextEditingController();


  // ✏️ SAVE USERNAME
  Future<void> _saveUsername() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .update({'username': _usernameController.text.trim()});

    setState(() {
      _isEditingName = false;
    });
  }

  // 🔐 CHANGE PASSWORD
  Future<void> _changePassword() async {
    await FirebaseAuth.instance
        .sendPasswordResetEmail(email: user!.email!);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Password reset email sent ✉️")),
    );
  }

  // 🚪 LOGOUT
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD8B4F8), Color(0xFFC084FC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: CircularProgressIndicator());
              }

              final data =
                  snapshot.data!.data() as Map<String, dynamic>;

              _usernameController.text = data['username'];

              return Column(
                children: [
                  // 🔙 BACK BUTTON
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 👤 PROFILE IMAGE
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.purple,
                        backgroundImage: data['photoUrl'] != null &&
                                data['photoUrl'] != ""
                            ? NetworkImage(data['photoUrl'])
                            : null,
                        child: data['photoUrl'] == null ||
                                data['photoUrl'] == ""
                            ? const Icon(Icons.person,
                                size: 50, color: Colors.white)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            /*decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            )*/
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ✏️ USERNAME
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _isEditingName
                          ? SizedBox(
                              width: 160,
                              child: TextField(
                                controller: _usernameController,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                ),
                              ),
                            )
                          : Text(
                              data['username'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      IconButton(
                        icon: Icon(
                          _isEditingName ? Icons.check : Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed:
                            _isEditingName ? _saveUsername : () {
                              setState(() => _isEditingName = true);
                            },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _infoCard("Email", data['email']),
                  _infoCard("Role", data['role'] ?? "User"),

                  const Spacer(),

                  _actionButton(
                    icon: Icons.lock_reset,
                    label: "Change Password",
                    onTap: _changePassword,
                  ),

                  _actionButton(
                    icon: Icons.logout,
                    label: "Logout",
                    onTap: _logout,
                  ),

                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _infoCard(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.bold)),
            Text(value),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.purple),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

