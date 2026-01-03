import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  // 🔹 MOCK DATA (replace with Firebase later)
  List<Map<String, dynamic>> get mockHistory => [
        _item("Washer", 2, "2025-12-09 13:00", 30),
        _item("Dryer", 2, "2025-12-09 13:40", 45),
        _item("Washer", 2, "2025-11-23 13:00", 30),
        _item("Dryer", 2, "2025-11-23 13:40", 45),
        _item("Washer", 2, "2025-10-12 21:00", 30),
        _item("Dryer", 2, "2025-10-12 21:40", 45),
        _item("Washer", 2, "2025-10-07 20:00", 30),
        _item("Dryer", 2, "2025-10-07 20:40", 45),
      ];

  static Map<String, dynamic> _item(
    String type,
    int no,
    String time,
    int duration,
  ) {
    return {
      "type": type,
      "no": no,
      "time": DateTime.parse(time),
      "duration": duration,
      "price": 5.00,
      "status": "Completed",
    };
  }

  @override
  Widget build(BuildContext context) {
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
              _historyContainer(),
            ],
          ),
        ),
      ),
    );
  }

  // 🔝 TOP BAR
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
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // 📦 WHITE CONTAINER
  Widget _historyContainer() {
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
                Text(
                  "Usage History",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: mockHistory.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = mockHistory[index];
                  return _historyCard(item);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🧾 HISTORY CARD
  Widget _historyCard(Map<String, dynamic> item) {
    final isWasher = item['type'] == "Washer";
    final date = DateFormat("yyyy-MM-dd").format(item['time']);
    final time = DateFormat("HH:mm").format(item['time']);

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
                Text(
                  "${item['type']} #${item['no']}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$date  $time",
                  style: const TextStyle(color: Colors.purple),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.timer,
                        size: 14, color: Colors.purple),
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
              Text(
                "RM ${item['price'].toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "Completed",
                  style: TextStyle(
                    color: Colors.green,
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

  // 🧺 ICON
  Widget _machineIcon(bool isWasher) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isWasher
              ? [const Color(0xFF9B59B6), const Color(0xFFB97AD9)]
              : [const Color(0xFFB97AD9), const Color(0xFFD8B4F8)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        isWasher ? Icons.local_laundry_service : Icons.dry,
        color: Colors.white,
      ),
    );
  }
}
