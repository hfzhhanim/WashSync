import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'sign_in_page.dart';
import 'report_page.dart';           
import 'feedback_rating_page.dart';   
import 'history_page.dart'; 

import 'wallet_page.dart';
import 'payment_screen.dart';
import 'washer_page.dart';
import 'dryer_page.dart';
import 'profile_page.dart';

class NavItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  User? get user => FirebaseAuth.instance.currentUser;

  void _navigateTo(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final navItems = [
      NavItem(
        icon: Icons.person_outline,
        label: "Profile",
        onTap: () {
          setState(() => _selectedIndex = 0);
          _navigateTo(ProfilePage()); 
        },
      ),
      NavItem(
        icon: Icons.history,
        label: "History",
        onTap: () {
          setState(() => _selectedIndex = 1);
          _navigateTo(HistoryPage()); 
        },
      ),
      NavItem(
        icon: Icons.report_outlined,
        label: "Report",
        onTap: () {
          setState(() => _selectedIndex = 2);
          _navigateTo(const ReportPage());
        },
      ),
      NavItem(
        icon: Icons.feedback_outlined,
        label: "Feedback",
        onTap: () {
          setState(() => _selectedIndex = 3);
          _navigateTo(const FeedbackRatingPage());
        },
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB388FF), Color(0xFFE1BEE7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _topBar(context),
              const SizedBox(height: 16),
              Transform.translate(
                offset: const Offset(0, -6),
                child: _userCard(user!),
              ), 
              const SizedBox(height: 16),
              _stats(user!), 
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Machines Status",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // WASHER BAR
              _machineBar(
                title: "Washer",
                collectionPath: "washers",
                icon: Icons.local_laundry_service,
                color: const Color(0xFF9B59B6),
                onTap: () => _navigateTo(const WasherPage()), 
              ),
              const SizedBox(height: 12),
              
              // DRYER BAR
              _machineBar(
                title: "Dryer",
                collectionPath: "dryers",
                icon: Icons.heat_pump,
                color: const Color(0xFFB97AD9),
                onTap: () => _navigateTo(const DryerPage()), 
              ),
              
              const Spacer(),
              _bottomNav(navItems),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            "assets/icons/logoWashSync.png",
            height: 52,
            width: 52,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          const Text(
            "WashSync",
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

  Widget _userCard(User user) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox(height: 80);
        final data = snapshot.data!.data() as Map<String, dynamic>;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFA500FF), Color(0xFF7A00CC)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(radius: 28, backgroundColor: Colors.purple, child: Icon(Icons.person, color: Colors.white)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Hello!~~~", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text(
                      data['username'] ?? "User",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      data['email'] ?? "",
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _stats(User user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usage_history')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                String usageCount = "0";
                if (snapshot.hasData) {
                  usageCount = snapshot.data!.docs.length.toString();
                }
                return _statCard(usageCount, "Total Uses", Icons.show_chart, () {
                    setState(() => _selectedIndex = 1);
                    _navigateTo(HistoryPage()); 
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                double balance = 0.0;
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  balance = (data['balance'] ?? 0.0).toDouble();
                }
                return _statCard(
                  "RM ${balance.toStringAsFixed(2)}", 
                  "Balance", 
                  Icons.account_balance_wallet, 
                  () => _navigateTo(WalletPage(amountToDeduct: -1.0)) 
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, VoidCallback? onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 6,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, color: Colors.purple, size: 34),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  // FIXED MACHINE BAR LOGIC
  Widget _machineBar({
    required String title, 
    required String collectionPath, 
    required IconData icon, 
    required Color color, 
    required VoidCallback onTap
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collectionPath).snapshots(),
      builder: (context, snapshot) {
        int total = 0;
        int available = 0;

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          total = docs.length;
          DateTime now = DateTime.now();

          available = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            
            // 1. Check if "In Use"
            bool isInUse = data['currentRemark'] == 'In Use' || data['status'] == 'In Use';

            // 2. Check Maintenance (Timestamp Logic)
            bool isUnderMaintenance = data['status'] == 'Maintenance';
            if (data['maintenanceStart'] != null && data['maintenanceStart'] is Timestamp) {
              DateTime maintStart = (data['maintenanceStart'] as Timestamp).toDate();
              // Machine is offline if start time has passed AND it's not being used 
              // (or it will lock once currentRemark is cleared)
              if (now.isAfter(maintStart) && !isInUse) {
                isUnderMaintenance = true;
              }
            }

            // Return true if machine is actually free
            return !isInUse && !isUnderMaintenance;
          }).length;
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color, 
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
               BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
            ]
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("$available of $total available", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("View", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _bottomNav(List<NavItem> items) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, -6)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) => _navItemUI(items[index], index)),
        ),
      ),
    );
  }

  Widget _navItemUI(NavItem item, int index) {
    final bool isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: item.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.purple.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, color: isActive ? Colors.purple : Colors.grey, size: 24),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                color: isActive ? Colors.purple : Colors.grey,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}