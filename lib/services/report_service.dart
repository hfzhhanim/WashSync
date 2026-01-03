import 'package:cloud_firestore/cloud_firestore.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // This function returns a live 'Stream' of data from your 'reports' collection
  Stream<QuerySnapshot> getReportsStream() {
    return _firestore
        .collection('userReports') // Make sure this matches your Firestore collection name exactly
        .orderBy('timestamp', descending: true) // Shows newest reports at the top
        .snapshots();
  }
  // Add this inside your ReportService class
Future<void> updateReportStatus(String reportId, String newStatus) async {
  try {
    await _firestore
        .collection('userReports') 
        .doc(reportId)
        .update({'status': newStatus});
  } catch (e) {
    print("Error updating report: $e");
    rethrow;
  }
}

}
