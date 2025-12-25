// lib/admin_main_screen.dart
import 'package:flutter/material.dart';
import 'package:washsync_app/screens/sign_in_page.dart';
import 'admin_dashboard_page.dart';
import 'admin_reports_page.dart';
import 'admin_maintenance_page.dart';
import 'admin_analytics_page.dart';
import 'screens/admin_promo_page.dart';
import 'admin_sign_in_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SizedBox();
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(25),
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;

        final username = data?['username'] ?? 'Admin';
        final email = data?['email'] ?? user.email ?? '';

        return Padding(
          padding: const EdgeInsets.all(25.0),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                // 👤 Avatar
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Colors.purple, size: 20),
                ),

                const SizedBox(width: 12),

                // 🧾 Username + Email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        email,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // 🚪 LOGOUT BUTTON (RIGHT SIDE)
                IconButton(
                  icon: const Icon(
                    Icons.logout,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: 'Logout',
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();

                    if (!context.mounted) return;

                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const AdminSignInPage()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}