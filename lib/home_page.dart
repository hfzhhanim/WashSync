import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Team's Pages (Relative paths from lib/ folder)
import 'sign_in_page.dart';
import 'report_page.dart';           
import 'feedback_rating_page.dart';   

// YOUR Wallet & Payment Pages (Inside the screens folder)
import 'screens/wallet_page.dart';
import 'screens/payment_screen.dart';
import 'screens/washer_page.dart';
import 'screens/dryer_page.dart';
import 'screens/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  
  void _navigateTo(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      extendBody: true, 
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD8B4F8), Color(0xFFC084FC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _topBar(),
              const SizedBox(height: 10),
              _userCard(user),
              const SizedBox(height: 15),
              _statsSection(user), // 2 Equal sized boxes
              const SizedBox(height: 25),
              
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Select Service", 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 15),

              // Service Selection Cards
              _serviceNavigationCard(
                title: "Washer",
                subtitle: "5 machines available",
                icon: Icons.local_laundry_service,
                color: const Color(0xFF9B59B6),
                onTap: () => _navigateTo(const WasherPage()),
              ),
              const SizedBox(height: 12),
              _serviceNavigationCard(
                title: "Dryer",
                subtitle: "5 machines available",
                icon: Icons.dry,
                color: const Color(0xFFB97AD9),
                onTap: () => _navigateTo(const DryerPage()),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- STATS SECTION: 2 Equal Boxes (Voucher Removed) ---
  Widget _statsSection(User user) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 100);
        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        double bal = (data['balance'] ?? 0.0).toDouble();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // Left: Total Uses (Equal Size)
              Expanded(
                child: _statBox("${data['totalUses'] ?? 0}", "Total Uses", Icons.auto_graph, null)
              ),
              const SizedBox(width: 15),
              // Right: Wallet Balance (Equal Size & Clickable)
              Expanded(
                child: _statBox(
                  "RM ${bal.toStringAsFixed(2)}", 
                  "Balance", 
                  Icons.account_balance_wallet,
                  () => _navigateTo(const WalletPage(amountToDeduct: -1.0)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statBox(String val, String label, IconData icon, VoidCallback? onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.purple, size: 28),
              const SizedBox(height: 8),
              Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  // --- SERVICE NAVIGATION CARDS ---
  Widget _serviceNavigationCard({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 40),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("WashSync", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
    );
  }

  Widget _userCard(User user) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        String name = "User";
        if (snapshot.hasData && snapshot.data!.exists) {
          name = (snapshot.data!.data() as Map<String, dynamic>)['username'] ?? "User";
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.purple)),
                const SizedBox(width: 15),
                Text("Welcome back, $name!", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 70,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navIcon(Icons.history, "History", () => _navigateTo(const WalletPage(amountToDeduct: -1.0))),
          _navIcon(Icons.report_problem_outlined, "Report", () => _navigateTo(const ReportPage())),
          const CircleAvatar(radius: 25, backgroundColor: Colors.purple, child: Icon(Icons.home, color: Colors.white)),
          _navIcon(Icons.rate_review_outlined, "Feedback", () => _navigateTo(const FeedbackRatingPage())),
          _navIcon(Icons.person_outline, "Profile", () => _navigateTo(const ProfilePage())),
        ],
      ),
    );
  }

  Widget _navIcon(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.purple, size: 24),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.purple)),
        ],
      ),
    );
  }
}