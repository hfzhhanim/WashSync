import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current logged-in user
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
              // Passing user UID to filter results
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
          const Text(
            "History",
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
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
            const Row(
              children: [
                Icon(Icons.update, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  "Usage History",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: uid == null
                  ? const Center(child: Text("User not logged in."))
                  : StreamBuilder<QuerySnapshot>(
                      // Listening to the specific user's history
                      stream: FirebaseFirestore.instance
                          .collection('usage_history')
                          .where('userId', isEqualTo: uid)
                          .orderBy('time', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text("Error: ${snapshot.error}"));
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history_toggle_off, size: 60, color: Colors.grey),
                                SizedBox(height: 10),
                                Text("No usage records found.", style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          );
                        }

                        final docs = snapshot.data!.docs;

                        return ListView.separated(
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final data = docs[index].data() as Map<String, dynamic>;
                            return _historyCard(data);
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

  Widget _historyCard(Map<String, dynamic> item) {
    final bool isWasher = item['type'] == "Washer";

    // Convert Firestore Timestamp to DateTime safely
    DateTime dateTime;
    if (item['time'] is Timestamp) {
      dateTime = (item['time'] as Timestamp).toDate();
    } else {
      dateTime = DateTime.now();
    }

    final date = DateFormat("yyyy-MM-dd").format(dateTime);
    final time = DateFormat("HH:mm").format(dateTime);

    // Dynamic Status Styling
    String status = item['status'] ?? "Completed";
    Color statusBgColor = Colors.green.shade50;
    Color statusTextColor = Colors.green;

    if (status == "In Progress") {
      statusBgColor = Colors.blue.shade50;
      statusTextColor = Colors.blue;
    } else if (status == "Pending") {
      statusBgColor = Colors.orange.shade50;
      statusTextColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.purple.shade50),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          _machineIcon(isWasher),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${item['type']} #${item['no']}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text("$date  $time", style: const TextStyle(color: Colors.purple, fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      "${item['duration'] ?? 30} mins",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "RM ${(item['price'] ?? 0.0).toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _machineIcon(bool isWasher) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isWasher ? const Color(0xFFF3E5F5) : const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        isWasher ? Icons.local_laundry_service : Icons.dry,
        color: isWasher ? Colors.purple : Colors.blue,
      ),
    );
  }
}