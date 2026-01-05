import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

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
          const Text("History", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _historyContainer(String? uid) {
    return Expanded(
      child: Container(
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
                SizedBox(width: 8),
                Text("Usage History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // 🔹 REAL-TIME LINK: Fetching only this user's history
                stream: FirebaseFirestore.instance
                    .collection('usage_history')
                    .where('userId', isEqualTo: uid) 
                    .orderBy('time', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No usage records found."));
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
    final isWasher = item['type'] == "Washer";
    // Handling Firestore Timestamp to DateTime
    final DateTime dateTime = (item['time'] as Timestamp).toDate();
    final date = DateFormat("yyyy-MM-dd").format(dateTime);
    final time = DateFormat("HH:mm").format(dateTime);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.purple.shade100),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _machineIcon(isWasher),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${item['type']} #${item['no']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("$date  $time", style: const TextStyle(color: Colors.purple)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.timer, size: 14, color: Colors.purple),
                    const SizedBox(width: 4),
                    Text("${item['duration']} minutes"),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("RM ${(item['price'] ?? 0.0).toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: item['status'] == "Completed" ? Colors.green.shade100 : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['status'] ?? "Pending",
                  style: TextStyle(
                    color: item['status'] == "Completed" ? Colors.green : Colors.orange,
                    fontSize: 12,
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
        gradient: LinearGradient(
          colors: isWasher ? [const Color(0xFF9B59B6), const Color(0xFFB97AD9)] : [const Color(0xFFB97AD9), const Color(0xFFD8B4F8)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(isWasher ? Icons.local_laundry_service : Icons.dry, color: Colors.white),
    );
  }
}