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
        if (mounted) setState(() => isLoading = false);
        return;
      }
      final doc = await FirebaseFirestore.instance.collection('admins').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          adminName = doc.data()?['username'] ?? "Admin";
          isLoading = false;
        });
      } else if (mounted) {
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
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
              Text(
                isLoading ? 'Welcome...' : 'Welcome, $adminName!',
                style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              /// 🔢 REAL-TIME SUMMARY CARDS
              _buildRealTimeSummary(),

              const SizedBox(height: 40),
              const Text(
                'System Status Summary',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              /// 📊 REAL-TIME TABLE (Maintenance Until Column Removed)
              _buildRealTimeStatusTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRealTimeSummary() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('washers').snapshots(),
      builder: (context, washerSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('dryers').snapshots(),
          builder: (context, dryerSnap) {
            if (!washerSnap.hasData || !dryerSnap.hasData) {
              return const Center(child: LinearProgressIndicator());
            }

            final washerDocs = washerSnap.data!.docs;
            final dryerDocs = dryerSnap.data!.docs;
            final allDocs = [...washerDocs, ...dryerDocs];
            
            // Safe counting logic to prevent null errors
            int total = allDocs.length;
            int available = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              return (data?['status'] ?? 'Available') == 'Available';
            }).length;

            int inUse = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              return (data?['status'] ?? '') == 'In Use';
            }).length;

            int maintenance = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              return (data?['status'] ?? '') == 'Maintenance';
            }).length;

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 1.3,
              children: [
                _buildSquare('Total Machines', total.toString()),
                _buildSquare('Available', available.toString()),
                _buildSquare('In Use', inUse.toString()),
                _buildSquare('Maintenance', maintenance.toString()),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRealTimeStatusTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('washers').snapshots(),
      builder: (context, washerSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('dryers').snapshots(),
          builder: (context, dryerSnap) {
            if (!washerSnap.hasData || !dryerSnap.hasData) return const SizedBox();

            List<Map<String, dynamic>> tableData = [];
            
            void processDocs(List<QueryDocumentSnapshot> docs, String type) {
              for (var doc in docs) {
                final data = doc.data() as Map<String, dynamic>?;
                if (data != null) {
                  tableData.add({
                    'type': type,
                    'id': doc.id,
                    'status': data['status'] ?? 'Available',
                  });
                }
              }
            }

            processDocs(washerSnap.data!.docs, 'Washer');
            processDocs(dryerSnap.data!.docs, 'Dryer');

            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
              ),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
                columns: const [
                  DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Machine No', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: tableData.map((data) {
                  return DataRow(
                    cells: [
                      DataCell(Text(data['type'].toString())),
                      DataCell(Text(data['id'].toString())),
                      DataCell(_buildStatusBadge(data['status'].toString())),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'Available' ? Colors.green : status == 'In Use' ? Colors.blue : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(
        status, 
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)
      ),
    );
  }

  Widget _buildSquare(String title, String value) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Color(0xFFE292FE), Color(0xFFBD61FF)]),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}