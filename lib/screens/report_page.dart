import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  bool _isSubmitted = false;
  String? _imagePath;

  final List<int> _machineNumbers = List.generate(5, (index) => index + 1);

  final Map<IssueType, String> _issueMap = {
    IssueType.notTurningOn: 'Machine not turning on',
    IssueType.leakingWater: 'Water leakage',
    IssueType.stuckDrum: 'Drum not spinning / drum stuck',
    IssueType.excessiveVibration: 'Excessive vibration during operation',
    IssueType.loudNoise: 'Unusual or loud noise',
    IssueType.clothesDamaged: 'Damaging or tearing clothes',
    IssueType.other: 'Other (please specify in description)',
  };

  final TextStyle _headerStyle = const TextStyle(
    color: Color(0xFF110C26),
    fontSize: 18,
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
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: Color(0xFF011FB6), width: 2.0),
      ),
    );
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to submit a report.')),
        );
        return;
      }

      try {
        await FirebaseFirestore.instance.collection('userReports').add({
          'userId': user.uid,
          'userName': user.displayName ?? user.email ?? 'Unknown User',
          'category': _selectedCategory.toString().split('.').last,
          'machineNumber': _selectedMachineNumber,
          'issueType': _issueMap[_selectedIssue] ?? 'Other',
          'description': _description,
          'imagePath': _imagePath,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'Pending',
        });

        setState(() {
          _isSubmitted = true;
        });

        _showSuccessDialog();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: ${e.toString()}')),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Center(
            child: Icon(Icons.check_circle, color: Colors.green, size: 48),
          ),
          content: const Text(
            "Issue has been successfully reported!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK', style: TextStyle(color: Color(0xFF011FB6), fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Back to home
              },
            ),
          ],
        );
      },
    );
  }

  void _attachImage() {
    setState(() {
      _imagePath = 'path/to/uploaded/image.jpg';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image attachment simulated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Issue', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xC2A669D4),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Category", style: _headerStyle),
                const SizedBox(height: 8),
                DropdownButtonFormField<MachineCategory>(
<<<<<<< HEAD
                  initialValue: _selectedCategory,
=======
                  value: _selectedCategory,
>>>>>>> 3388b30be0a1c74806ad5c57fb8aa22408713e17
                  decoration: _inputDecoration("Select machine type"),
                  items: MachineCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val),
                  validator: (val) => val == null ? 'Please select category' : null,
                ),
                const SizedBox(height: 25),
                Text("Machine Number", style: _headerStyle),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
<<<<<<< HEAD
                  initialValue: _selectedMachineNumber,
=======
                  value: _selectedMachineNumber,
>>>>>>> 3388b30be0a1c74806ad5c57fb8aa22408713e17
                  decoration: _inputDecoration("Select the machine number"),
                  items: _machineNumbers.map((number) {
                    return DropdownMenuItem(
                      value: number,
                      child: Text("Machine $number"),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedMachineNumber = val),
                  validator: (val) => val == null ? 'Please select number' : null,
                ),
                const SizedBox(height: 25),
                Text("Issue", style: _headerStyle),
                const SizedBox(height: 8),
                DropdownButtonFormField<IssueType>(
<<<<<<< HEAD
                  initialValue: _selectedIssue,
=======
                  value: _selectedIssue,
>>>>>>> 3388b30be0a1c74806ad5c57fb8aa22408713e17
                  decoration: _inputDecoration("Select the primary issue"),
                  items: IssueType.values.map((issue) {
                    return DropdownMenuItem(
                      value: issue,
                      child: Text(_issueMap[issue] ?? 'Other'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedIssue = val),
                  validator: (val) => val == null ? 'Please select issue' : null,
                ),
                const SizedBox(height: 25),
                Text("Attachment", style: _headerStyle),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _attachImage,
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _imagePath == null ? Icons.add_a_photo_outlined : Icons.image,
                          color: _imagePath == null ? Colors.grey : Colors.green,
                        ),
                        Text(_imagePath == null ? "Add image" : "Image Attached"),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Text("Description", style: _headerStyle),
                const SizedBox(height: 8),
                TextFormField(
                  onSaved: (val) => _description = val ?? '',
                  maxLines: 3,
                  decoration: _inputDecoration("Details..."),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF011FB6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      _isSubmitted ? "SUBMITTED" : "SUBMIT",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}