import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'profile_page.dart';
import 'history_page.dart';
import 'report_page.dart';
import 'feedback_rating_page.dart';

/// ---------------- NAV ITEM MODEL ----------------
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

/// ---------------- MOCK PAGES ----------------
class WasherPage extends StatelessWidget {
  const WasherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Washer")),
      body: const Center(child: Text("Washer Page")),
    );
  }
}

class DryerPage extends StatelessWidget {
  const DryerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dryer")),
      body: const Center(child: Text("Dryer Page")),
    );
  }
}

/// ---------------- HOME PAGE ----------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? get user => FirebaseAuth.instance.currentUser;
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final navItems = [
      NavItem(
        icon: Icons.person_outline,
        label: "Profile",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfilePage()),
          );
        },
      ),
      NavItem(
        icon: Icons.history,
        label: "History",
        onTap: () {
          debugPrint("NAV → History");
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HistoryPage()),
          );
        },
      ),
      NavItem(
        icon: Icons.report_outlined,
        label: "Report",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReportPage()),
          );
        },
      ),
      NavItem(
        icon: Icons.feedback_outlined,
        label: "Feedback",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FeedbackRatingPage()),
          );
        },
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFD8B4F8),
              Color(0xFFC084FC),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _topBar(context),
              const SizedBox(height: 16),
              _userCard(user!),
              const SizedBox(height: 16),
              _stats(user!),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "Machines",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),


              _washerCard(),
              const SizedBox(height: 12),
              _dryerCard(),
              const Spacer(),
              _bottomNav(navItems),
            ],
          ),
        ),
      ),
    );
  }

  /// ---------------- TOP BAR ----------------
  Widget _topBar(BuildContext context) {
    const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6), // makes logo pop
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset(
                  "assets/icons/logoWashSync.png",
                  height: 32,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "WashSync",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20, // slightly bigger
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ---------------- USER CARD ----------------
  Widget _userCard(User user) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const CircularProgressIndicator();
        }


        final data = snapshot.data!.data() as Map<String, dynamic>;


        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.purple,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Hello 👋"),
                    Text(
                      data['username'] ?? "User",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      data['email'],
                      style: const TextStyle(color: Colors.purple),
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

  /// ---------------- STATS ----------------
  Widget _stats(User user) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox();
        }


        final data = snapshot.data!.data() as Map<String, dynamic>;


        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _statCard("${data['totalUses'] ?? 0}", "Total Uses", Icons.show_chart),
              const SizedBox(width: 10),
              _statCard("RM ${data['balance'] ?? 0}", "Balance",
                  Icons.account_balance_wallet),
              const SizedBox(width: 10),
              _statCard("${data['vouchers'] ?? 0}", "Vouchers",
                  Icons.confirmation_number),
            ],
          ),
        );
      },
    );
  }


  Widget _statCard(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.purple),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.purple),
            ),
          ],
        ),
      ),
    );
  }

  /// ---------------- MACHINE CARD ----------------
  Widget _washerCard() {
    const SizedBox(height: 24);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('machines')
            .doc('washer')
            .snapshots(),
        builder: (context, snapshot) {
          int available = 0;
          int total = 0;


          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            available = data['available'] ?? 0;
            total = data['total'] ?? 0;
          }


          return _machineCard(
            title: "Washer",
            subtitle: "$available of $total available",
            icon: Icons.local_laundry_service,
            color: const Color(0xFF9B59B6),
            onTap: () {
              // 🔥 NAVIGATE TO FRIEND’S PAGE LATER
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WasherPage(), // <-- friend page
                ),
              );
            },
          );
        },
      ),
    );
  }


  // 🔥 DRYER
  Widget _dryerCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('machines')
            .doc('dryer')
            .snapshots(),
        builder: (context, snapshot) {
          int available = 0;
          int total = 0;


          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            available = data['available'] ?? 0;
            total = data['total'] ?? 0;
          }


          return _machineCard(
            title: "Dryer",
            subtitle: "$available of $total available",
            icon: Icons.dry,
            color: const Color(0xFFB97AD9),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DryerPage(), // <-- friend page
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _machineCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 6), // 👈 pop effect
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Icon(Icons.chevron_right, color: Colors.white, size: 28),
          ],
        ),
      ),
    );
  }


  /// ---------------- BOTTOM NAV ----------------
  Widget _bottomNav(List<NavItem> items) {
    return Container(
      height: 70,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFB48DD6),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          items.length,
          (index) => _navItem(
            item: items[index],
            isActive: _currentIndex == index,
            onTap: () {
              setState(() => _currentIndex = index);
              items[index].onTap();
            },
          ),
        ),
      ),
    );
  }


  Widget _navItem({
    required NavItem item,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withOpacity(0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              color: Colors.white,
              size: isActive ? 28 : 24,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight:
                    isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------- STAT BOX ----------------
/*class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}*/
