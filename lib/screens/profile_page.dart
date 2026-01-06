import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  bool _isUploading = false; 

  final TextEditingController _usernameController = TextEditingController();

  // 📸 PICK IMAGE FROM GALLERY & UPLOAD TO FIREBASE
  Future<void> _pickImage() async {
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Compressing to save storage space
    );

    if (pickedFile != null) {
      setState(() => _isUploading = true);

      try {
        File imageFile = File(pickedFile.path);
        
        // 1. Upload to Firebase Storage
        Reference ref = FirebaseStorage.instance
            .ref()
            .child('user_profiles')
            .child('${user!.uid}.jpg');

        await ref.putFile(imageFile);

        // 2. Get the Download URL
        String downloadUrl = await ref.getDownloadURL();

        // 3. Update Firestore with the new URL
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({'photoUrl': downloadUrl});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile picture updated! ✅")),
          );
        }
      } catch (e) {
        debugPrint("Upload Error: $e");
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  // ✏️ SAVE USERNAME TO FIRESTORE
  Future<void> _saveUsername() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .update({'username': _usernameController.text.trim()});

    setState(() {
      _isEditingName = false;
    });
  }

  // 🔐 CHANGE PASSWORD (SEND EMAIL)
  Future<void> _changePassword() async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset email sent ✉️")),
      );
    }
  }

  // 🚪 LOGOUT
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
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

              final data = snapshot.data!.data() as Map<String, dynamic>;
              if (!_isEditingName) {
                _usernameController.text = data['username'] ?? "";
              }

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

                  // 👤 PROFILE IMAGE WITH CAMERA OVERLAY
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white24,
                        backgroundImage: data['photoUrl'] != null && data['photoUrl'] != ""
                            ? NetworkImage(data['photoUrl'])
                            : null,
                        child: _isUploading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : (data['photoUrl'] == null || data['photoUrl'] == ""
                                ? const Icon(Icons.person, size: 60, color: Colors.white)
                                : null),
                      ),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.purple, size: 20),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // ✏️ EDITABLE USERNAME
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _isEditingName
                          ? SizedBox(
                              width: 180,
                              child: TextField(
                                controller: _usernameController,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: const InputDecoration(border: InputBorder.none),
                              ),
                            )
                          : Text(
                              data['username'] ?? "Guest",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      IconButton(
                        icon: Icon(
                          _isEditingName ? Icons.check : Icons.edit,
                          color: Colors.white,
                        ),
                        onPressed: _isEditingName ? _saveUsername : () => setState(() => _isEditingName = true),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // 📋 INFO CARDS
                  _infoCard("Email", data['email'] ?? "No Email"),
                  _infoCard("Role", data['role'] ?? "User"),

                  const Spacer(),

                  // 🛠 ACTION BUTTONS
                  _actionButton(
                    icon: Icons.lock_reset,
                    label: "Change Password",
                    onTap: _changePassword,
                  ),

                  _actionButton(
                    icon: Icons.logout,
                    label: "Logout",
                    onTap: _logout,
                    isLogout: true,
                  ),

                  const SizedBox(height: 30),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _infoCard(String title, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _actionButton({required IconData icon, required String label, required VoidCallback onTap, bool isLogout = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isLogout ? Colors.redAccent.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: isLogout ? Border.all(color: Colors.redAccent) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isLogout ? Colors.redAccent : Colors.purple),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: isLogout ? Colors.redAccent : Colors.purple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}