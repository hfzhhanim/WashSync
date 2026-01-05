import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Team's Pages
import 'sign_in_page.dart';
import 'report_page.dart';           
import 'feedback_rating_page.dart';   
import 'history_page.dart';

// YOUR Wallet & Payment Pages
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

Future<void> bookMachine(String docId) async {
  final ref = FirebaseFirestore.instance.collection('machines').doc(docId);

  await FirebaseFirestore.instance.runTransaction((transaction) async {
    final snapshot = await transaction.get(ref);

    if (!snapshot.exists) return;

    int available = snapshot['available'];

    if (available > 0) {
      transaction.update(ref, {
        'available': available - 1,
      });
    }
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
          _navigateTo(const ProfilePage());
        },
      ),
      NavItem(
        icon: Icons.history,
        label: "History",
        onTap: () {
          setState(() => _selectedIndex = 1);
          _navigateTo(const HistoryPage());
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
          gradient: const LinearGradient(
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
              ), // Original welcome user layout
              const SizedBox(height: 16),
              _stats(user!), // 2 Equal sized boxes (Uses & Balance)
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Machines",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // RESTORED: Single bar layout for navigation to sub-pages
              _machineBar(
                title: "Washer",
                docId: "washer",
                icon: Icons.local_laundry_service,
                color: const Color(0xFF9B59B6),
                onTap: () => _navigateTo(const WasherPage()),
              ),
              const SizedBox(height: 12),
              _machineBar(
                title: "Dryer",
                docId: "dryer",
                icon: Icons.dry,
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

  // --- TOP BAR ---
  Widget _topBar(BuildContext context) {
    return Container(
      height: 52, // controlled, premium header height
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo
          Image.asset(
            "assets/icons/logoWashSync.png",
            height: 52,
            width: 52,
            fit: BoxFit.contain,
          ),

          const SizedBox(width: 12),

          // App name
          const Text(
            "WashSync",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  // --- USER CARD ---
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
                colors: [
                  Color(0xFFA500FF),
                  Color(0xFF7A00CC),
                ],
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
                    const Text("Hello~~~",
                      style: TextStyle(color: Colors.white70, fontSize: 14)),

                    Text(
                      data['username'] ?? "User",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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

  // --- STATS (2 Equal Boxes, No Vouchers) ---
  Widget _stats(User user) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox();
        final data = snapshot.data!.data() as Map<String, dynamic>;
        double balance = (data['balance'] ?? 0.0).toDouble();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _statCard("${data['totalUses'] ?? 0}", "Total Uses", Icons.show_chart, null),
              const SizedBox(width: 12),
              _statCard(
                "RM ${balance.toStringAsFixed(2)}", 
                "Balance", 
                Icons.account_balance_wallet, 
                () => _navigateTo(const WalletPage(amountToDeduct: -1.0))
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String value, String label, IconData icon, VoidCallback? onTap) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.2),
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.purple.withOpacity(0.15),
          highlightColor: Colors.purple.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
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
      ),
    );
  }

  // --- MACHINE BAR (Original Bar Design) ---
  Widget _machineBar({required String title, required String docId, required IconData icon, required Color color, required VoidCallback onTap}) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('machines').doc(docId).snapshots(),
      builder: (context, snapshot) {
        int available = 0, total = 0;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          available = data['available'] ?? 0;
          total = data['total'] ?? 0;
        }
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color, 
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 0,
                ),
                child: const Text(
                  "View",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- BOTTOM NAV (Original Style) ---
  Widget _bottomNav(List<NavItem> items) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            items.length,
            (index) => _navItemUI(items[index], index),
          ),
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
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
          ? Colors.purple.withOpacity(0.12)
          : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isActive ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 250),
              child: Icon(
                item.icon,
                color: isActive ? Colors.purple : Colors.grey,
                size: 24,
              ),
            ),
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