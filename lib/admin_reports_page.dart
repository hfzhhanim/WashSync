import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/report_service.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  final ReportService _reportService = ReportService();
  String _selectedFilter = 'All'; 
  Map<String, dynamic>? _selectedReportData;
  String? _selectedReportId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background to make the table pop
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Reports Management',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'View and resolve machine issues reported by users.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),

            // 1. FILTER BAR
            _buildFilterBar(),
            const SizedBox(height: 20),

            // 2. REPORT TABLE
            _buildTableContainer(),

            const SizedBox(height: 30),

            // 3. DETAIL VIEW (Conditional)
            if (_selectedReportData != null) _buildDetailView(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Row(
      children: ['All', 'Pending', 'Resolved'].map((status) {
        bool isSelected = _selectedFilter == status;
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: FilterChip(
            label: Text(status),
            selected: isSelected,
            onSelected: (val) => setState(() {
              _selectedFilter = status;
              _selectedReportData = null; // Close details when switching filters
            }),
            selectedColor: Colors.purple[100],
            checkmarkColor: Colors.purple,
            labelStyle: TextStyle(
              color: isSelected ? Colors.purple[900] : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTableContainer() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: _reportService.getReportsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LinearProgressIndicator();

          var docs = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String status = data['status'] ?? 'Pending';
            if (_selectedFilter == 'All') return true;
            return status.toLowerCase() == _selectedFilter.toLowerCase();
          }).toList();

          return DataTable(
            headingRowHeight: 60,
            dataRowMaxHeight: 70,
            showCheckboxColumn: false,
            columns: const [
              DataColumn(label: Text('Report ID', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('No.', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Issue Type', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              String status = data['status'] ?? 'Pending';
              bool isResolved = status.toLowerCase() == 'resolved';

              return DataRow(
                onSelectChanged: (_) {
                   setState(() {
                    _selectedReportData = data;
                    _selectedReportId = doc.id;
                  });
                },
                cells: [
                  DataCell(Text('#${doc.id.substring(0, 5)}')),
                  DataCell(Text(data['machineType'] ?? data['category'] ?? 'Washer')),
                  DataCell(Text(data['machineNumber']?.toString() ?? '-')),
                  DataCell(SizedBox(width: 150, child: Text(data['issueType'] ?? 'Other', overflow: TextOverflow.ellipsis))),
                  DataCell(_buildStatusBadge(status)),
                  DataCell(
                    TextButton.icon(
                      icon: Icon(isResolved ? Icons.visibility : Icons.build_circle_outlined, size: 18),
                      label: Text(isResolved ? 'View' : 'View / Resolve'),
                      onPressed: () {
                        setState(() {
                          _selectedReportData = data;
                          _selectedReportId = doc.id;
                        });
                      },
                    ),
                  ),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildDetailView() {
    bool isResolved = _selectedReportData!['status']?.toString().toLowerCase() == 'resolved';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.purple.shade100, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Report Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => setState(() => _selectedReportData = null), icon: const Icon(Icons.close)),
            ],
          ),
          const Divider(),
          const SizedBox(height: 15),
          Row(
            children: [
              _infoTile('Machine', _selectedReportData!['machineType'] ?? _selectedReportData!['category']),
              const SizedBox(width: 50),
              _infoTile('Machine No.', _selectedReportData!['machineNumber']?.toString()),
              const SizedBox(width: 50),
              _infoTile('Reported By', _selectedReportData!['userName'] ?? 'User'),
            ],
          ),
          const SizedBox(height: 25),
          const Text('Issue Description:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 8),
          Text(_selectedReportData!['description'] ?? 'No description provided.'),
          const SizedBox(height: 30),
          
          if (!isResolved)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                await _reportService.updateReportStatus(_selectedReportId!, 'Resolved');
                setState(() => _selectedReportData = null);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report Marked as Resolved')));
              },
              child: const Text('Mark as Resolved'),
            ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, dynamic value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value?.toString() ?? '-', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    bool isResolved = status.toLowerCase() == 'resolved';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isResolved ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isResolved ? Colors.green : Colors.orange),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: isResolved ? Colors.green[700] : Colors.orange[800], fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}