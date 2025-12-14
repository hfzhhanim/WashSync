import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // **NEW: Firestore**
import 'package:firebase_auth/firebase_auth.dart'; // **NEW: Firebase Auth**

// --- Global variables remain the same ---
enum MachineCategory { washer, dryer }
enum IssueType { notTurningOn, leakingWater, stuckDrum, excessiveVibration, loudNoise, clothesDamaged, other }

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});
  @override
  ReportPageState createState() => ReportPageState();
}

class ReportPageState extends State<ReportPage> {
    
    // --- State Variables for the Form ---
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    MachineCategory? _selectedCategory;
    
    // State variable for the selected machine number (1-5)
    int? _selectedMachineNumber; 
    
    IssueType? _selectedIssue;
    String _description = '';
    
    bool _isSubmitted = false;

    // List of available machine numbers (1 to 5)
    final List<int> _machineNumbers = List.generate(5, (index) => index + 1);

    // Map IssueType to user-friendly strings
    final Map<IssueType, String> _issueMap = {
        IssueType.notTurningOn: 'Machine not turning on',
        IssueType.leakingWater: 'Water leakage',
        IssueType.stuckDrum: 'Drum not spinning / drum stuck',
        IssueType.excessiveVibration: 'Excessive vibration during operation',
        IssueType.loudNoise: 'Unusual or loud noise',
        IssueType.clothesDamaged: 'Damaging or tearing clothes',
        IssueType.other: 'Other (please specify in description)',
    };
    
    String? _imagePath; 

    // --- Consistent Header Style ---
    final TextStyle _headerStyle = const TextStyle(
        color: Color(0xFF110C26), // Darker text color
        fontSize: 18,
        fontWeight: FontWeight.bold,
    );

    // --- Input Decoration Style ---
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

    void _handleSubmit() async { // **UPDATED: Added 'async' keyword**
        if (_formKey.currentState!.validate()) {
            _formKey.currentState!.save();
            
            // 1. Get the current user ID
            final user = FirebaseAuth.instance.currentUser;
            
            if (user == null) {
                // User is not logged in. Show error or handle appropriately.
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You must be logged in to submit an issue report.'))
                );
                return;
            }

            try {
                // 2. **NEW: FIREBASE WRITE LOGIC**
                await FirebaseFirestore.instance.collection('issueReports').add({
                    'userId': user.uid, // <-- SAVES THE UNIQUE FIREBASE USER ID (UID)
                    'category': _selectedCategory.toString().split('.').last,
                    'machineNumber': _selectedMachineNumber,
                    'issueType': _selectedIssue.toString().split('.').last,
                    'description': _description,
                    'imagePath': _imagePath, // Path is currently simulated, but data field is ready
                    'timestamp': FieldValue.serverTimestamp(),
                    'status': 'New', // Default status for a new report
                });

                // 3. Success Logic
                setState(() {
                    _isSubmitted = true;
                });
                
                _showSuccessDialog();

            } catch (e) {
                // 4. Error Handling (e.g., security rules, network failure)
                print("Error submitting report to Firestore: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Submission failed: ${e.toString()}'))
                );
            }
        }
    }
    
    void _showSuccessDialog() {
        showDialog(
            context: context,
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
                                Navigator.of(context).pop(); // Pop back to home screen
                            },
                        ),
                    ],
                );
            },
        );
    }
    
    void _attachImage() {
        // Simulate image attachment
        setState(() {
            _imagePath = 'path/to/uploaded/image.jpg';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image attachment simulated (1 file attached)'))
        );
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text(
                    'Report Issue', 
                    style: TextStyle(fontWeight: FontWeight.bold)
                ),
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
                                // ------------------------------------
                                // 1. Category Dropdown
                                // ------------------------------------
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Text("Category", style: _headerStyle),
                                ),
                                DropdownButtonFormField<MachineCategory>(
                                    value: _selectedCategory,
                                    decoration: _inputDecoration("Select machine type"),
                                    items: MachineCategory.values.map((MachineCategory category) {
                                        return DropdownMenuItem<MachineCategory>(
                                            value: category,
                                            child: Text(category.toString().split('.').last.toUpperCase()),
                                        );
                                    }).toList(),
                                    onChanged: (MachineCategory? newValue) {
                                        setState(() {
                                            _selectedCategory = newValue;
                                        });
                                    },
                                    validator: (value) => value == null ? 'Please select a category' : null,
                                ),

                                // ------------------------------------
                                // 2. Machine Number Dropdown
                                // ------------------------------------
                                Padding(
                                    padding: const EdgeInsets.only(top: 25.0, bottom: 8.0),
                                    child: Text("Machine Number", style: _headerStyle),
                                ),
                                DropdownButtonFormField<int>(
                                    value: _selectedMachineNumber,
                                    decoration: _inputDecoration("Select the machine number "),
                                    items: _machineNumbers.map((int number) {
                                        return DropdownMenuItem<int>(
                                            value: number,
                                            child: Text("Machine $number"),
                                        );
                                    }).toList(),
                                    onChanged: (int? newValue) {
                                        setState(() {
                                            _selectedMachineNumber = newValue;
                                        });
                                    },
                                    validator: (value) => value == null ? 'Please select a machine number' : null,
                                ),

                                // ------------------------------------
                                // 3. Issue Options Dropdown
                                // ------------------------------------
                                Padding(
                                    padding: const EdgeInsets.only(top: 25.0, bottom: 8.0),
                                    child: Text("Issue", style: _headerStyle),
                                ),
                                DropdownButtonFormField<IssueType>(
                                    value: _selectedIssue,
                                    decoration: _inputDecoration("Select the primary issue"),
                                    items: IssueType.values.map((IssueType issue) {
                                        return DropdownMenuItem<IssueType>(
                                            value: issue,
                                            child: Text(_issueMap[issue] ?? 'Unknown Issue'),
                                        );
                                    }).toList(),
                                    onChanged: (IssueType? newValue) {
                                        setState(() {
                                            _selectedIssue = newValue;
                                        });
                                    },
                                    validator: (value) => value == null ? 'Please select an issue' : null,
                                ),

                                // ------------------------------------
                                // 4. Attachment Button
                                // ------------------------------------
                                Padding(
                                    padding: const EdgeInsets.only(top: 25.0, bottom: 8.0),
                                    child: Text("Attachment", style: _headerStyle),
                                ),
                                InkWell(
                                    onTap: _attachImage,
                                    child: Container(
                                        height: 120,
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.grey.shade300, width: 1.0),
                                        ),
                                        alignment: Alignment.center,
                                        width: double.infinity,
                                        child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                                Icon(
                                                    _imagePath == null ? Icons.add_a_photo_outlined : Icons.image, 
                                                    size: 35, 
                                                    color: _imagePath == null ? Colors.grey[600] : Colors.green.shade600
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                    _imagePath == null ? "Add image (Optional)" : "Image Attached (Tap to re-upload)",
                                                    style: TextStyle(
                                                        color: _imagePath == null ? Colors.grey[700] : Colors.green.shade600, 
                                                        fontSize: 14, 
                                                        fontWeight: FontWeight.w500
                                                    ),
                                                ),
                                            ]
                                        ),
                                    ),
                                ),

                                // ------------------------------------
                                // 5. Description Text Field
                                // ------------------------------------
                                Padding(
                                    padding: const EdgeInsets.only(top: 25.0, bottom: 8.0),
                                    child: Text("Description", style: _headerStyle),
                                ),
                                TextFormField(
                                    onSaved: (value) => _description = value ?? '',
                                    maxLines: 4,
                                    maxLength: 500, 
                                    decoration: _inputDecoration("Provide more details about the issue..."),
                                ),

                                // ------------------------------------
                                // 6. Submit Button
                                // ------------------------------------
                                Padding(
                                    padding: const EdgeInsets.only(top: 40.0, bottom: 20), 
                                    child: Center(
                                        child: SizedBox( 
                                            width: double.infinity, 
                                            child: ElevatedButton( 
                                                onPressed: _handleSubmit,
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor: _isSubmitted ? Colors.green.shade600 : const Color(0xFF011FB6), 
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                                    shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    elevation: 5,
                                                ),
                                                child: Text(
                                                    _isSubmitted ? "SUBMITTED" : "SUBMIT",
                                                    style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                    ),
                                                ),
                                            ),
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