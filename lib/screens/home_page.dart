import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Team's Pages (Using ../ to go out of 'screens' folder if they are in lib root)
import 'sign_in_page.dart';
import 'report_page.dart';           
import 'feedback_rating_page.dart';   

// YOUR Wallet & Payment Pages (In the same 'screens' folder)
import 'wallet_page.dart';
import 'payment_screen.dart';
import 'profile_page.dart'; // Ensure these exist or use friend's mock pages

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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? get user => FirebaseAuth.instance.currentUser;
  int _currentIndex = 0;

  // Navigation Helper
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

    // Navigation items linked to your working pages
    final navItems = [
      NavItem(
        icon: Icons.person_outline,
        label: "Profile",
        onTap: () => _navigateTo(const ProfilePage()),
      ),
      NavItem(
        icon: Icons.history,
        label: "History",
        onTap: () => _navigateTo(const WalletPage(amountToDeduct: -1.0)),
      ),
      NavItem(
        icon: Icons.report_outlined,
        label: "Report",
        onTap: () => _navigateTo(const ReportPage()),
      ),
      NavItem(
        icon: Icons.feedback_outlined,
        label: "Feedback",
        onTap: () => _navigateTo(const FeedbackRatingPage()),
      ),
    ];

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
              const SizedBox(height: 16),
              _userCard(user!),
              const SizedBox(height: 16),
              _stats(user!), // Fixed with tap support
              const SizedBox(height: 20),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel("Washers"),
                      _machineGrid(type: 'Washer', count: 5, icon: Icons.local_laundry_service),
                      const SizedBox(height: 20),
                      _sectionLabel("Dryers"),
                      _machineList(type: 'Dryer', count: 5, icon: Icons.dry),
                    ],
                  ),
                ),
              ),
              _bottomNav(navItems),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  /// ---------------- TOP BAR ----------------
  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset("assets/icons/logoWashSync.png", height: 32, 
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.local_laundry_service, color: Colors.white)),
              ),
              const SizedBox(width: 10),
              const Text("WashSync", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
    );
  }

  /// ---------------- USER CARD ----------------
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
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)]),
            child: Row(
              children: [
                const CircleAvatar(radius: 28, backgroundColor: Colors.purple, child: Icon(Icons.person, color: Colors.white)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Hello 👋"),
                    Text(data['username'] ?? "User", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(data['email'] ?? "", style: const TextStyle(color: Colors.purple, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ---------------- STATS (FIXED FOR TAP) ----------------
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
              _statCard("${data['totalUses'] ?? 0}", "Uses", Icons.show_chart, null),
              const SizedBox(width: 10),
              // THE WALLET TAP BOX
              _statCard(
                "RM ${balance.toStringAsFixed(2)}", 
                "Balance", 
                Icons.account_balance_wallet, 
                () => _navigateTo(const WalletPage(amountToDeduct: -1.0))
              ),
              const SizedBox(width: 10),
              _statCard("${data['vouchers'] ?? 0}", "Vouchers", Icons.confirmation_number, null),
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
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(icon, color: Colors.purple, size: 20),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text(label, style: const TextStyle(color: Colors.purple, fontSize: 10)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ---------------- MACHINE LIST ----------------
  Widget _machineGrid({required String type, required int count, required IconData icon}) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: count,
        itemBuilder: (context, index) {
          return Container(
            width: 140,
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.purple, size: 30),
                Text("$type ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Text("RM 5.00", style: TextStyle(color: Colors.grey, fontSize: 10)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _navigateTo(const PaymentScreen()),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), minimumSize: const Size(0, 30)),
                  child: const Text("PAY NOW", style: TextStyle(fontSize: 10)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _machineList({required String type, required int count, required IconData icon}) => _machineGrid(type: type, count: count, icon: icon);

  /// ---------------- BOTTOM NAV ----------------
  Widget _bottomNav(List<NavItem> items) {
    return Container(
      height: 70,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFB48DD6), borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) => _navItem(
          item: items[index], 
          isActive: _currentIndex == index, 
          onTap: () {
            setState(() => _currentIndex = index);
            items[index].onTap();
          },
        )),
      ),
    );
  }

  Widget _navItem({required NavItem item, required bool isActive, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, color: Colors.white, size: isActive ? 28 : 24),
          Text(item.label, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}