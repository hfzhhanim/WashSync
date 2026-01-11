import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAnalyticsPage extends StatelessWidget {
  const AdminAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 35.0, left: 47.0, right: 47.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Feedback Summary',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            // 1. DYNAMIC FEEDBACK & RATING DISTRIBUTION
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('userFeedback').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                int totalFeedback = docs.length;
                double sumRating = 0;
                Map<int, int> distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['rating'] != null) {
                    double rValue = (data['rating'] as num).toDouble();
                    sumRating += rValue;
                    int starKey = rValue.round().clamp(1, 5);
                    distribution[starKey] = (distribution[starKey] ?? 0) + 1;
                  }
                }

                double avgRating = totalFeedback == 0 ? 0.0 : sumRating / totalFeedback;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildSummaryCard("Average Rating", avgRating.toStringAsFixed(1), Icons.star, Colors.orange),
                        const SizedBox(width: 20),
                        _buildSummaryCard("Total Feedback", totalFeedback.toString(), Icons.feedback, Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 40),
                    _buildRatingDistribution(distribution, totalFeedback),
                  ],
                );
              },
            ),

            const SizedBox(height: 50),

            // 2. DYNAMIC USER REGISTRATION
            const Text("Total User Registration (By Month)", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text("Error: ${snapshot.error}");
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                Map<int, int> monthlyCounts = {1:0, 2:0, 3:0, 4:0, 5:0, 6:0, 7:0, 8:0, 9:0, 10:0, 11:0, 12:0};
                
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  dynamic createdAt = data['createdAt'];
                  
                  if (createdAt != null) {
                    DateTime? date;
                    if (createdAt is Timestamp) {
                      date = createdAt.toDate();
                    } else if (createdAt is String) {
                      date = DateTime.tryParse(createdAt);
                    }

                    if (date != null) {
                      int month = date.month;
                      monthlyCounts[month] = (monthlyCounts[month] ?? 0) + 1;
                    }
                  }
                }
                
                return _buildUserRegistrationChart(monthlyCounts);
              },
            ),

            const SizedBox(height: 50),
            
            // 3. DYNAMIC DAILY MACHINE USAGE
            const Text("Daily Machine Usage", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text("Error: ${snapshot.error}");
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                // Index 1 = Mon, 7 = Sun
                Map<int, int> washerDaily = {1:0, 2:0, 3:0, 4:0, 5:0, 6:0, 7:0};
                Map<int, int> dryerDaily = {1:0, 2:0, 3:0, 4:0, 5:0, 6:0, 7:0};

                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  String? type = data['type']; 
                  dynamic startTime = data['startTime'];

                  if (startTime != null) {
                    DateTime? date;
                    if (startTime is String) {
                      date = DateTime.tryParse(startTime);
                    } else if (startTime is Timestamp) {
                      date = startTime.toDate();
                    }

                    if (date != null) {
                      int weekday = date.weekday; // Returns 1 (Mon) - 7 (Sun)
                      if (type == 'Washer') {
                        washerDaily[weekday] = (washerDaily[weekday] ?? 0) + 1;
                      } else if (type == 'Dryer') {
                        dryerDaily[weekday] = (dryerDaily[weekday] ?? 0) + 1;
                      }
                    }
                  }
                }

                return _buildDailyUsageChart(washerDaily, dryerDaily);
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildDailyUsageChart(Map<int, int> washerDaily, Map<int, int> dryerDaily) {
    // Determine the highest count for axis scaling
    int maxW = washerDaily.values.reduce((a, b) => a > b ? a : b);
    int maxD = dryerDaily.values.reduce((a, b) => a > b ? a : b);
    double maxY = (maxW > maxD ? maxW : maxD).toDouble();

    return Container(
      height: 350,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: BarChart(
        BarChartData(
          maxY: maxY < 5 ? 5 : maxY + 2,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  int idx = value.toInt();
                  if (idx > 0 && idx < days.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(days[idx], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          barGroups: [1, 2, 3, 4, 5, 6, 7].map((day) {
            return _makeGroupData(
              day, 
              (washerDaily[day] ?? 0).toDouble(), 
              (dryerDaily[day] ?? 0).toDouble()
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildUserRegistrationChart(Map<int, int> monthlyCounts) {
    List<FlSpot> spots = [];
    for (int i = 1; i <= 12; i++) {
      spots.add(FlSpot((i - 1).toDouble(), (monthlyCounts[i] ?? 0).toDouble()));
    }

    double maxCount = monthlyCounts.values.reduce((a, b) => a > b ? a : b).toDouble();

    return Container(
      height: 350,
      padding: const EdgeInsets.only(top: 20, right: 30, left: 10, bottom: 10),
      decoration: _cardDecoration(),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxCount < 5 ? 5 : maxCount + 2,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                  int idx = value.toInt();
                  if (idx >= 0 && idx < 12) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(months[idx], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blueAccent,
              barWidth: 4,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: Colors.blueAccent.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingDistribution(Map<int, int> distribution, int total) {
    final stars = [5, 4, 3, 2, 1];
    final colors = [Colors.green, Colors.lightGreen, Colors.yellow[700]!, Colors.orange, Colors.red];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: List.generate(stars.length, (index) {
          int star = stars[index];
          int count = distribution[star] ?? 0;
          double percentage = total == 0 ? 0 : count / total;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                SizedBox(width: 60, child: Text("$star Star")),
                const SizedBox(width: 10),
                Expanded(
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.grey[200],
                    color: colors[index],
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 15),
                SizedBox(width: 40, child: Text("$count", style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              Row(
                children: [
                  Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  if (title == "Average Rating") const Icon(Icons.star, color: Colors.orange, size: 24),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double washerY, double dryerY) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(toY: washerY, color: Colors.blueAccent, width: 10),
      BarChartRodData(toY: dryerY, color: Colors.purpleAccent, width: 10),
    ]);
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.grey.shade200),
    );
  }
}