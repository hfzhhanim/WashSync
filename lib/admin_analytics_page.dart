import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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
            // Header
            const Text(
              'Feedback Summary',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),

            // Summary Cards
            Row(
              children: [
                _buildSummaryCard("Average Rating", "4.8", Icons.star, Colors.orange),
                const SizedBox(width: 20),
                _buildSummaryCard("Total Feedback", "487", Icons.feedback, Colors.blue),
              ],
            ),
            const SizedBox(height: 40),

            const Text("Rating Distribution", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildRatingDistribution(),

            const SizedBox(height: 50),

            const Text("Total User Registration (By Month)", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildUserRegistrationChart(),

            const SizedBox(height: 50),

            // Peak Hour Usage Header with Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Peak Hour Usage (Machines in Use)", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    _buildLegendItem("Washer", Colors.blueAccent),
                    const SizedBox(width: 15),
                    _buildLegendItem("Dryer", Colors.purpleAccent),
                  ],
                )
              ],
            ),
            const SizedBox(height: 20),
            _buildPeakHourChart(),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // --- WIDGET: PEAK HOUR USAGE (Sequential 24h Sequence) ---
  Widget _buildPeakHourChart() {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 5, // Capped at 5 machines
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1, // 1 to 5
                getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 12)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  // Show labels every 4 hours in sequence
                  if (value % 4 == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('${value.toInt()}:00', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          // SEQUENTIAL TIME SLOTS
          barGroups: [
            _makeGroupData(0, 1, 0),   // 12:00 AM
            _makeGroupData(4, 0, 1),   // 04:00 AM
            _makeGroupData(8, 2, 3),   // 08:00 AM
            _makeGroupData(12, 4, 2),  // 12:00 PM
            _makeGroupData(16, 3, 5),  // 04:00 PM
            _makeGroupData(20, 5, 4),  // 08:00 PM
            _makeGroupData(23, 2, 1),  // 11:00 PM
          ],
        ),
      ),
    );
  }

  // Helper method for Grouped Bars
  BarChartGroupData _makeGroupData(int x, double washerY, double dryerY) {
    return BarChartGroupData(
      x: x,
      barsSpace: 4, 
      barRods: [
        BarChartRodData(
          toY: washerY,
          color: Colors.blueAccent,
          width: 10,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
        BarChartRodData(
          toY: dryerY,
          color: Colors.purpleAccent,
          width: 10,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  // --- HELPERS (STYLING & LEGEND) ---
  Widget _buildLegendItem(String name, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
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

  Widget _buildRatingDistribution() {
    List<Map<String, dynamic>> data = [
      {"stars": 5, "count": 320, "color": Colors.green},
      {"stars": 4, "count": 110, "color": Colors.lightGreen},
      {"stars": 3, "count": 40, "color": Colors.yellow[700]},
      {"stars": 2, "count": 12, "color": Colors.orange},
      {"stars": 1, "count": 5, "color": Colors.red},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: data.map((item) {
          double percentage = item['count'] / 487;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                SizedBox(width: 60, child: Text("${item['stars']} Star")),
                const SizedBox(width: 10),
                Expanded(
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.grey[200],
                    color: item['color'],
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 15),
                SizedBox(width: 40, child: Text("${item['count']}", style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUserRegistrationChart() {
    return Container(
      height: 350,
      padding: const EdgeInsets.only(top: 20, right: 30, left: 10, bottom: 10),
      decoration: _cardDecoration(),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                  if (value.toInt() >= 0 && value.toInt() < months.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(months[value.toInt()], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
          lineBarsData: [
            LineChartBarData(
              spots: [
                const FlSpot(0, 50), const FlSpot(1, 80), const FlSpot(2, 120),
                const FlSpot(3, 190), const FlSpot(4, 250), const FlSpot(5, 310),
              ],
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
    );
  }
}