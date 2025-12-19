import 'package:flutter/material.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

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
              const Text(
                'Welcome, Admin 1 !',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 30),

              // 1. FOUR BOXES SECTION
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4, // Set to 4 columns
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.3, // Adjusted to be slightly wider than tall
                children: [
                  _buildSquare('Total Machines', '10'),
                  _buildSquare('Available', '4'),
                  _buildSquare('In Use', '5'),
                  _buildSquare('Maintenance', '1'),
                ],
              ),

              const SizedBox(height: 40),

              // 2. SYSTEM STATUS SUMMARY TABLE
              const Text(
                'System Status Summary',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
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

  // Widget for the Summary Table
  Widget _buildStatusTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
          )
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
          return DataRow(cells: [
            DataCell(Text(index % 2 == 0 ? 'Washer' : 'Dryer')),
            DataCell(Text('${index + 1}')),
            DataCell(_buildStatusBadge(index)),
            const DataCell(Text('10:45 AM')),
          ]);
        }),
      ),
    );
  }

  // Helper for Status Badge in Table
  Widget _buildStatusBadge(int index) {
    List<String> statuses = ['Available', 'In Use', 'Maintenance'];
    String status = statuses[index % 3];
    Color color = status == 'Available' 
        ? Colors.green 
        : (status == 'In Use' ? Colors.blue : Colors.orange);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  // Your existing Square Widget (slightly optimized for 4 columns)
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
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}