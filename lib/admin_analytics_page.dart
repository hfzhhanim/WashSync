import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminAnalyticsPage extends StatelessWidget {
  const AdminAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(47.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Weekly Usage Overview", 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usage_history')
                  .where('timestamp', isGreaterThanOrEqualTo: DateTime.now().subtract(const Duration(days: 7)))
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();

                // Map integer weekdays (1-7) to counts
                Map<int, int> dailyData = {};
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['timestamp'] != null) {
                    DateTime date = (data['timestamp'] as Timestamp).toDate();
                    dailyData[date.weekday] = (dailyData[date.weekday] ?? 0) + 1;
                  }
                }

                return _buildWeeklyUsageChart(dailyData);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyUsageChart(Map<int, int> dailyData) {
    // 1. Force the chart to have 7 points so axes always show
    final Map<int, int> fullWeek = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    fullWeek.addAll(dailyData);

    double maxVal = fullWeek.values.reduce((a, b) => a > b ? a : b).toDouble();

    List<BarChartGroupData> barGroups = fullWeek.entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.toDouble(), // Even 0.0 height keeps the axis alive
            color: const Color(0xFFBD61FF),
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return Container(
      height: 500,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          BarChart(
            BarChartData(
              maxY: maxVal < 5 ? 5 : maxVal + 1, // Fixed scale for empty states
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                      if (value.toInt() >= 1 && value.toInt() <= 7) {
                        return Text(days[value.toInt()], 
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold));
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
              barGroups: barGroups,
            ),
          ),
          // Show message only if truly empty
          if (dailyData.isEmpty)
            const Text("No usage data available", 
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}