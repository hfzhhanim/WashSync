import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

enum MachineCategory { washer, dryer }

enum IssueType {
  notTurningOn,
  leakingWater,
  stuckDrum,
  excessiveVibration,
  loudNoise,
  clothesDamaged,
  other
}

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});
  @override
  ReportPageState createState() => ReportPageState();
}

class ReportPageState extends State<ReportPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  MachineCategory? _selectedCategory;
  int? _selectedMachineNumber;
  IssueType? _selectedIssue;
  String _description = '';
  bool _isSubmitting = false;
  
  // Real Image Variables
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  final List<int> _machineNumbers = List.generate(5, (index) => index + 1);

  final Map<IssueType, String> _issueMap = {
    IssueType.notTurningOn: 'Machine not turning on',
    IssueType.leakingWater: 'Water leakage',
    IssueType.stuckDrum: 'Drum not spinning / drum stuck',
    IssueType.excessiveVibration: 'Excessive vibration',
    IssueType.loudNoise: 'Unusual or loud noise',
    IssueType.clothesDamaged: 'Damaging clothes',
    IssueType.other: 'Other (specify below)',
  };

  // --- STYLING ---
  final TextStyle _headerStyle = const TextStyle(
    color: Color(0xFF110C26),
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      fillColor: Colors.white,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Color(0xC2A669D4), width: 2.0),
      ),
    );
  }

  // 📸 REAL IMAGE PICKER (Gallery + Camera)
  Future<void> _pickImage() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 50, // Compresses image for faster upload
      );

      if (image != null) {
        setState(() {
          _pickedImage = File(image.path);
        });
      }
    }
  }

  // ☁️ FIREBASE STORAGE UPLOAD
  Future<String?> _uploadImage(File imageFile) async {
    try {
      String fileName = path.basename(imageFile.path);
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('report_images/${DateTime.now().millisecondsSinceEpoch}_$fileName');

      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Upload error: $e");
      return null;
    }
  }

  // 📝 SUBMIT TO FIRESTORE
  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      setState(() => _isSubmitting = true);

      try {
        String? downloadUrl;
        if (_pickedImage != null) {
          downloadUrl = await _uploadImage(_pickedImage!);
        }

        await FirebaseFirestore.instance.collection('userReports').add({
          'userId': user.uid,
          'userName': user.displayName ?? user.email ?? 'Unknown User',
          'category': _selectedCategory.toString().split('.').last,
          'machineNumber': _selectedMachineNumber,
          'issueType': _issueMap[_selectedIssue] ?? 'Other',
          'description': _description,
          'imageUrl': downloadUrl, // The real URL from Storage
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'Pending',
        });

        if (mounted) _showSuccessDialog();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: ${e.toString()}')),
        );
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text(
          "Report Submitted Successfully!",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Back to Home
              },
              child: const Text("OK", style: TextStyle(fontSize: 18)),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Issue'),
        backgroundColor: const Color(0xC2A669D4),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Category", style: _headerStyle),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<MachineCategory>(
                    decoration: _inputDecoration("Select machine type"),
                    items: MachineCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.name.toUpperCase()))).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val),
                    validator: (val) => val == null ? 'Please select a type' : null,
                  ),
                  const SizedBox(height: 20),
                  Text("Machine Number", style: _headerStyle),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    decoration: _inputDecoration("Select the machine number"),
                    items: _machineNumbers.map((n) => DropdownMenuItem(value: n, child: Text("Machine $n"))).toList(),
                    onChanged: (val) => setState(() => _selectedMachineNumber = val),
                    validator: (val) => val == null ? 'Please select a number' : null,
                  ),
                  const SizedBox(height: 20),
                  Text("Issue Type", style: _headerStyle),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<IssueType>(
                    decoration: _inputDecoration("Select the primary issue"),
                    items: IssueType.values.map((i) => DropdownMenuItem(value: i, child: Text(_issueMap[i]!))).toList(),
                    onChanged: (val) => setState(() => _selectedIssue = val),
                    validator: (val) => val == null ? 'Please select an issue' : null,
                  ),
                  const SizedBox(height: 20),
                  Text("Attachment", style: _headerStyle),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickImage,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: _pickedImage == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey),
                                Text("Select from Gallery or Camera", style: TextStyle(color: Colors.grey)),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(_pickedImage!, fit: BoxFit.cover),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text("Description", style: _headerStyle),
                  const SizedBox(height: 8),
                  TextFormField(
                    maxLines: 3,
                    decoration: _inputDecoration("Details..."),
                    onSaved: (val) => _description = val ?? '',
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF011FB6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSubmitting 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("SUBMIT", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isSubmitting)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}