import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth

class FeedbackRatingPage extends StatefulWidget {
	const FeedbackRatingPage ({super.key});
	@override
		FeedbackRatingPageState createState() => FeedbackRatingPageState();
	}

class FeedbackRatingPageState extends State<FeedbackRatingPage> {
    
    // --- State Variables ---
    int _currentRating = 0; // Rating from 0 to 5
    String _feedbackText = '';
    bool _isSubmitted = false;

    // --- Header Style (Consistent with ReportPage) ---
    final TextStyle _headerStyle = const TextStyle(
        color: Color(0xFF110C26), // Darker text color
        fontSize: 18,
        fontWeight: FontWeight.bold,
    );

    // --- Input Decoration Style (Consistent with ReportPage) ---
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
    
    // --- Submission Logic ---
    void _handleSubmit() async { // **UPDATED: Added 'async' keyword**
        if (_currentRating == 0) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please provide a rating before submitting.'))
            );
            return;
        }

        // Get the current user ID
        final user = FirebaseAuth.instance.currentUser;
        
        if (user == null) {
            // User is not logged in
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('You must be logged in to submit feedback.'))
            );
            return;
        }

        try {
            // Firebase write logic
            await FirebaseFirestore.instance.collection('userFeedback').add({
                'rating': _currentRating,
                'feedbackText': _feedbackText,
                'timestamp': FieldValue.serverTimestamp(), // Use server time
                'userId': user.uid, // Save the authenticated user's unique ID
            });
            
            // Success Logic
            setState(() {
                _isSubmitted = true;
            });
            
            _showSuccessDialog();
            
        } catch (e) {
            // 4. Error Handling
            print("Error submitting feedback to Firestore: $e");
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Submission failed. Please try again later.'))
            );
        }
    }
    
    // --- Success Dialog (Consistent with ReportPage) ---
    void _showSuccessDialog() {
        showDialog(
            context: context,
            builder: (BuildContext context) {
                return AlertDialog(
                    title: const Center(
                        child: Icon(Icons.check_circle, color: Colors.green, size: 48),
                    ),
                    content: const Text(
                        "Thank you for your valuable feedback!",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    actions: <Widget>[
                        TextButton(
                            child: const Text('OK', style: TextStyle(color: Color.fromARGB(255, 117, 2, 188), fontWeight: FontWeight.bold)),
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

	@override
	Widget build(BuildContext context) {
		return Scaffold(
            appBar: AppBar(
                title: const Text(
                    'Feedback & Rating', 
                    style: TextStyle(fontWeight: FontWeight.bold)
                ),
                backgroundColor: const Color(0xC2A669D4), 
                foregroundColor: Colors.white,
            ),
            body: Container( 
                color: Colors.grey.shade50, 
                child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            // ------------------------------------
                            // 1. Rating Section
                            // ------------------------------------
                            Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text("Rating", style: _headerStyle),
                            ),
                            Container(
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey.shade300, width: 1.0),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                                width: double.infinity,
                                child: Column(
                                    children: [
                                        // Display Feedback Text based on rating
                                        Text(
                                            _currentRating == 5 ? "Excellent!" : 
                                            _currentRating == 4 ? "Very Good" :
                                            _currentRating == 3 ? "Good" :
                                            _currentRating == 2 ? "Fair" :
                                            _currentRating == 1 ? "Poor" :
                                            "Tap a star to rate",
                                            style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                            ),
                                        ),
                                        const SizedBox(height: 15),
                                        // Star Rating Row
                                        Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: List.generate(5, (index) {
                                                return IconButton(
                                                    icon: Icon(
                                                        index < _currentRating ? Icons.star : Icons.star_border,
                                                        color: Colors.amber,
                                                        size: 40,
                                                    ),
                                                    onPressed: () {
                                                        setState(() {
                                                            _currentRating = index + 1;
                                                        });
                                                    },
                                                );
                                            }),
                                        ),
                                    ],
                                ),
                            ),
                            
                            // ------------------------------------
                            // 2. Feedback Text Field
                            // ------------------------------------
                            Padding(
                                padding: const EdgeInsets.only(top: 30.0, bottom: 8.0),
                                child: Text("Feedback", style: _headerStyle),
                            ),
                            TextFormField(
                                onChanged: (value) => _feedbackText = value,
                                maxLines: 5,
                                maxLength: 500,
                                decoration: _inputDecoration("Leave your feedback here..."),
                            ),

                            // ------------------------------------
                            // 3. Submit Button
                            // ------------------------------------
                            Padding(
                                padding: const EdgeInsets.only(top: 40.0, bottom: 20),
                                child: Center(
                                    child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                            onPressed: _handleSubmit,
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: _isSubmitted ? Colors.green.shade600 : const Color.fromARGB(255, 111, 18, 203),
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
		);
	}
}