import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sign_in_page.dart';
import 'report_page.dart';           // Your import
import 'feedback_rating_page.dart';   // Your import

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

// Keep these machine pages for now
class WasherPage extends StatelessWidget {
  const WasherPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Washer")), body: const Center(child: Text("Washer Page")));
}

class DryerPage extends StatelessWidget {
  const DryerPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Dryer")), body: const Center(child: Text("Dryer Page")));
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final List<NavItem> navItems;

  @override
  void initState() {
    super.initState();

    // Merging your navigation into your friend's bottom bar
    navItems = [
      NavItem(
        icon: Icons.person_outline,
        label: "Profile",
        onTap: () { /* Add Profile logic later */ },
      ),
      NavItem(
        icon: Icons.history,
        label: "History",
        onTap: () { /* Add History logic later */ },
      ),
      NavItem(
        icon: Icons.report_outlined,
        label: "Report",
        onTap: () {
          // YOUR NAVIGATION LOGIC
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportPage()));
        },
      ),
      NavItem(
        icon: Icons.feedback_outlined,
        label: "Feedback",
        onTap: () {
          // YOUR NAVIGATION LOGIC
          Navigator.push(context, MaterialPageRoute(builder: (context) => const FeedbackRatingPage()));
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
              _userCard(user),
              const SizedBox(height: 16),
              _stats(user),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Machines", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 12),
              _washerCard(),
              const SizedBox(height: 12),
              _dryerCard(),
              const Spacer(),
              _bottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset("assets/icons/logoWashSync.png", height: 30, errorBuilder: (context, error, stackTrace) => const Icon(Icons.local_laundry_service, color: Colors.white)),
              const SizedBox(width: 8),
              const Text("WashSync", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SignInPage()), (_) => false);
            },
          ),
        ],
      ),
    );
  }

  Widget _userCard(User user) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!.data() as Map<String, dynamic>;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const CircleAvatar(radius: 28, backgroundColor: Colors.purple, child: Icon(Icons.person, color: Colors.white)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Hello 👋"),
                    Text(data['username'] ?? "User", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(data['email'] ?? "", style: const TextStyle(color: Colors.purple)),
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
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox();
        final data = snapshot.data!.data() as Map<String, dynamic>;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _statCard("${data['totalUses'] ?? 0}", "Total Uses", Icons.show_chart),
              const SizedBox(width: 10),
              _statCard("RM ${data['balance'] ?? 0}", "Balance", Icons.account_balance_wallet),
              const SizedBox(width: 10),
              _statCard("${data['vouchers'] ?? 0}", "Vouchers", Icons.confirmation_number),
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
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Icon(icon, color: Colors.purple),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.purple, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _washerCard() {
    return _machineStreamCard(docId: 'washer', title: 'Washer', icon: Icons.local_laundry_service, color: const Color(0xFF9B59B6), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WasherPage())));
  }

  Widget _dryerCard() {
    return _machineStreamCard(docId: 'dryer', title: 'Dryer', icon: Icons.dry, color: const Color(0xFFB97AD9), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DryerPage())));
  }

  Widget _machineStreamCard({required String docId, required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('machines').doc(docId).snapshots(),
      builder: (context, snapshot) {
        int available = 0, total = 0;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          available = data['available'] ?? 0;
          total = data['total'] ?? 0;
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _machineCardUI(title: title, subtitle: "$available of $total available", icon: icon, color: color, onTap: onTap),
        );
      },
    );
  }

  Widget _machineCardUI({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 36),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ]),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _bottomNav() {
    return SizedBox(
      height: 80,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 60,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: const Color(0xFFB48DD6), borderRadius: BorderRadius.circular(24)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItemUI(navItems[0]),
                _navItemUI(navItems[1]),
                const SizedBox(width: 40),
                _navItemUI(navItems[2]),
                _navItemUI(navItems[3]),
              ],
            ),
          ),
          Positioned(top: 0, child: CircleAvatar(radius: 32, backgroundColor: const Color(0xFF8A3FFC), child: IconButton(icon: const Icon(Icons.home, color: Colors.white, size: 32), onPressed: () {}))),
        ],
      ),
    );
  }

  Widget _navItemUI(NavItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(item.icon, color: Colors.white, size: 24),
        Text(item.label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ]),
    );
  }
}