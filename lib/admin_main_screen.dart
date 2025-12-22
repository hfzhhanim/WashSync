// lib/admin_main_screen.dart
import 'package:flutter/material.dart';
import 'admin_dashboard_page.dart';
import 'admin_reports_page.dart';
import 'admin_maintenance_page.dart';
import 'admin_analytics_page.dart';
import 'screens/admin_promo_page.dart'; // Corrected import to match your root file location

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;

  // Define the list of content pages including the Promo Management page
  // The order here must match the index passed to _buildMenuItem
  static const List<Widget> _widgetOptions = <Widget>[
    AdminDashboardPage(),
    AdminReportsPage(),
    AdminMaintenancePage(),
    AdminAnalyticsPage(),
    AdminPromoPage(), // Index 4
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // --- SIDEBAR ---
          Container(
            width: 300, 
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFC084FC), Color(0xFF9333EA)],
              ),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 50, left: 25, bottom: 40),
                  child: Row(
                    children: [
                      Icon(Icons.menu, color: Colors.black, size: 28),
                      SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          'USM Laundry Admin', 
                          style: TextStyle(
                            fontSize: 20, 
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Sidebar Navigation Items
                _buildMenuItem('Dashboard Overview', 0, Icons.grid_view_rounded),
                _buildMenuItem('User Reports', 1, Icons.people_alt_outlined),
                _buildMenuItem('Maintenance & Operations', 2, Icons.settings_outlined),
                _buildMenuItem('Analytics & Report', 3, Icons.bar_chart_rounded),
                _buildMenuItem('Promo Code Settings', 4, Icons.discount_outlined), 
                
                const Spacer(), 
                
                _buildProfileSection(),
              ],
            ),
          ),

          // --- MAIN CONTENT AREA ---
          // Using IndexedStack prevents the pages from "reloading" every time you click
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _widgetOptions,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String title, int index, IconData icon) {
    final bool isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Icon(
                icon, 
                color: isSelected ? Colors.white : Colors.black87, 
                size: 22
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20), 
        ),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 18, 
              backgroundColor: Colors.white, 
              child: Icon(Icons.person, color: Colors.purple, size: 20)
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'admin1@gmail.com',
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 13, 
                  fontWeight: FontWeight.bold
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}