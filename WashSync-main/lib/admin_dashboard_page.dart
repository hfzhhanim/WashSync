import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  String adminName = "Admin";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAdminName();
  }

  Future<void> fetchAdminName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          adminName = doc.data()?['username'] ?? "Admin";
          isLoading = false;
        });
      } else {
        // Admin doc not found
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching admin name: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔥 WELCOME TEXT
              Text(
                isLoading ? 'Welcome...' : 'Welcome, $adminName!',
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 30),

              /// 🔢 SUMMARY CARDS
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.3,
                children: [
                  _buildSquare('Total Machines', '10'),
                  _buildSquare('Available', '4'),
                  _buildSquare('In Use', '5'),
                  _buildSquare('Maintenance', '1'),
                ],
              ),

              const SizedBox(height: 40),

              /// 📊 SYSTEM STATUS
              const Text(
                'System Status Summary',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              _buildStatusTable(),
            ],
          ),
        ),
      ),
    );
  }

  /// 📋 TABLE
  Widget _buildStatusTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
        columns: const [
          DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Machine No', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Last Update', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: List.generate(5, (index) {
          return DataRow(
            cells: [
              DataCell(Text(index.isEven ? 'Washer' : 'Dryer')),
              DataCell(Text('${index + 1}')),
              DataCell(_buildStatusBadge(index)),
              const DataCell(Text('10:45 AM')),
            ],
          );
        }),
      ),
    );
  }

  /// 🟢 STATUS BADGE
  Widget _buildStatusBadge(int index) {
    List<String> statuses = ['Available', 'In Use', 'Maintenance'];
    String status = statuses[index % 3];

    Color color = status == 'Available'
        ? Colors.green
        : status == 'In Use'
            ? Colors.blue
            : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  /// 🟣 SUMMARY CARD
  Widget _buildSquare(String title, String value) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE292FE), Color(0xFFBD61FF)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
