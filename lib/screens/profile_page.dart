import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'sign_in_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();

  bool _isEditing = false;
  bool _isUploading = false;

  File? _localProfileImage; // 🔥 IMAGE SIMULATION (LOCAL ONLY)

  final TextEditingController _nameController = TextEditingController();

  /// ================= IMAGE SIMULATION =================
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 40,
    );

    if (image == null) return;

    setState(() {
      _localProfileImage = File(image.path);
    });
  }

  /// ================= SAVE USERNAME =================
  Future<void> _saveName() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .update({'username': _nameController.text.trim()});

    setState(() => _isEditing = false);
  }

  /// ================= CHANGE PASSWORD =================
  Future<void> _changePassword() async {
    await FirebaseAuth.instance
        .sendPasswordResetEmail(email: user!.email!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent ✉️')),
      );
    }
  }

  /// ================= LOGOUT =================
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SignInPage()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7FF),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data =
              snapshot.data!.data() as Map<String, dynamic>? ?? {};

          final name = data['username'] ?? user!.email!.split('@').first;
          final email = data['email'] ?? user!.email!;
          final role = data['role'] ?? 'User';

          _nameController.text = name;

          int completed = 0;
          if (data['name'] != null) completed++;
          if (data['email'] != null) completed++;
          if (_localProfileImage != null) completed++;

          final completion = completed / 3;

          return Column(
            children: [
              /// ================= SCROLL =================
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      /// ================= HEADER =================
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: 180,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFD8B4FE),
                                  Color(0xFFC084FC),
                                ],
                              ),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(80),
                                bottomRight: Radius.circular(80),
                              ),
                            ),
                          ),

                          Positioned(
                            top: 50,
                            left: 16,
                            child: Row(
                              children: const [
                                BackButton(color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'User Profile',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Positioned(
                            bottom: -40,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 42,
                                      backgroundColor: Colors.white,
                                      backgroundImage:
                                          _localProfileImage != null
                                              ? FileImage(
                                                  _localProfileImage!)
                                              : null,
                                      child: _localProfileImage == null
                                          ? const Icon(
                                              Icons.person,
                                              size: 42,
                                              color: Colors.purple,
                                            )
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: CircleAvatar(
                                        radius: 14,
                                        backgroundColor: Colors.purple,
                                        child: const Icon(
                                          Icons.camera_alt,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 60),

                      /// ================= NAME =================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _isEditing
                              ? SizedBox(
                                  width: 180,
                                  child: TextField(
                                    controller: _nameController,
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                          IconButton(
                            icon: Icon(
                                _isEditing ? Icons.check : Icons.edit),
                            onPressed: _isEditing
                                ? _saveName
                                : () =>
                                    setState(() => _isEditing = true),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      /// ================= COMPLETION =================
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Profile Completion'),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: completion,
                              minHeight: 8,
                              backgroundColor:
                                  Colors.purple.shade100,
                              valueColor:
                                  const AlwaysStoppedAnimation(
                                      Colors.purple),
                            ),
                            const SizedBox(height: 6),
                            Text(
                                '${(completion * 100).toInt()}% completed'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      /// ================= INFO =================
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            _infoRow(Icons.email, email),
                            const SizedBox(height: 14),
                            _infoRow(Icons.verified_user, role),
                            const SizedBox(height: 14),
                            _infoRow(
                                Icons.calendar_month, 'Joined Jan 2026'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              /// ================= BOTTOM BUTTONS =================
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize:
                            const Size(double.infinity, 48),
                        side:
                            const BorderSide(color: Colors.purple),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: const Icon(Icons.lock,
                          color: Colors.purple),
                      label: const Text('Change Password',
                          style:
                              TextStyle(color: Colors.purple)),
                      onPressed: _changePassword,
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize:
                            const Size(double.infinity, 48),
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon:
                          const Icon(Icons.logout, color: Colors.red),
                      label: const Text('Logout',
                          style: TextStyle(color: Colors.red)),
                      onPressed: _logout,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.purple),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    );
  }
}
