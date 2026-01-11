import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryPage extends StatelessWidget {
  final String? filterType; // Optional: "Dryer" or "Washer"

  const HistoryPage({super.key, this.filterType});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD8B4F8), Color(0xFFC084FC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _topBar(context),
              const SizedBox(height: 12),
              _historyContainer(user?.uid),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.history, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            filterType == null ? "Usage History" : "$filterType History",
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _historyContainer(String? uid) {
    return Expanded(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.update, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  filterType == null ? "Recent Activity" : "Recent $filterType Activity",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: uid == null
                  ? const Center(child: Text("Please log in to view history."))
                  : StreamBuilder<QuerySnapshot>(
                      stream: _getFilteredStream(uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text("Error: ${snapshot.error}"));
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return _emptyState();
                        }

                        // Use a Map to ensure unique records (De-duplication)
                        final docs = snapshot.data!.docs;
                        final Map<String, dynamic> uniqueRecords = {};

                        for (var doc in docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final timestamp = data['time'] as Timestamp?;
                          final machineNo = data['no'] ?? '0';
                          final type = data['type'] ?? 'Unknown';
                          
                          if (timestamp != null) {
                            // Unique key: type + machine number + specific minute
                            String key = "${type}_${machineNo}_${timestamp.seconds ~/ 60}";
                            if (!uniqueRecords.containsKey(key)) {
                              uniqueRecords[key] = data;
                            }
                          }
                        }

                        final filteredList = uniqueRecords.values.toList();

                        return ListView.separated(
                          itemCount: filteredList.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _historyCard(filteredList[index]);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build the Firestore Query
  Stream<QuerySnapshot> _getFilteredStream(String uid) {
    Query query = FirebaseFirestore.instance
        .collection('usage_history')
        .where('userId', isEqualTo: uid);

    // FIX: Apply the type filter only if filterType is provided
    if (filterType != null) {
      query = query.where('type', isEqualTo: filterType);
    }

    return query.orderBy('time', descending: true).snapshots();
  }

  Widget _historyCard(Map<String, dynamic> item) {
    final String type = item['type'] ?? "Washer";
    final bool isWasher = type.toLowerCase() == "washer";
    final bool isDryer = type.toLowerCase() == "dryer";

    DateTime dateTime = (item['time'] is Timestamp) 
        ? (item['time'] as Timestamp).toDate() 
        : DateTime.now();

    final date = DateFormat("MMM dd, yyyy").format(dateTime);
    final time = DateFormat("hh:mm a").format(dateTime);

    String status = item['status'] ?? "Completed";
    Color statusTextColor = (status == "In Progress") ? Colors.blue : Colors.green;
    Color statusBgColor = statusTextColor.withOpacity(0.1);

    Color themeColor = isWasher ? Colors.purple : (isDryer ? Colors.blue : Colors.blueGrey);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: themeColor.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          _machineIcon(type),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$type #${item['no'] ?? '?'}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("$date  •  $time", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text("${item['duration'] ?? 0} mins", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("RM ${(item['price'] ?? 0.0).toDouble().toStringAsFixed(2)}", 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(12)),
                child: Text(status, style: TextStyle(color: statusTextColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _machineIcon(String type) {
    bool isWasher = type.toLowerCase() == "washer";
    bool isDryer = type.toLowerCase() == "dryer";

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isWasher ? const Color(0xFFF3E5F5) : (isDryer ? const Color(0xFFE3F2FD) : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        isWasher ? Icons.local_laundry_service : (isDryer ? Icons.dry_outlined : Icons.help_outline),
        color: isWasher ? Colors.purple : (isDryer ? Colors.blue : Colors.grey),
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 60, color: Colors.grey),
          SizedBox(height: 10),
          Text("No records found.", style: TextStyle(color: Colors.grey, fontSize: 16)),
          Text("Book a machine to see your history.", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}