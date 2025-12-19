import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sign_in_page.dart';

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

    navItems = [
      NavItem(
        icon: Icons.person_outline,
        label: "Profile",
        onTap: () {
          // TODO: Navigator.push(context, ...)
        },
      ),
      NavItem(
        icon: Icons.history,
        label: "History",
        onTap: () {
          // TODO
        },
      ),
      NavItem(
        icon: Icons.report_outlined,
        label: "Report",
        onTap: () {
          // TODO
        },
      ),
      NavItem(
        icon: Icons.feedback_outlined,
        label: "Feedback",
        onTap: () {
          // TODO
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
              _userCard(user),
              const SizedBox(height: 16),
              _stats(user),
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
              _bottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  // 🔝 TOP BAR
  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset("assets/icons/logoWashSync.png", height: 30),
              const SizedBox(width: 8),
              const Text(
                "WashSync",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const SignInPage()),
                (_) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  // 👤 USER CARD (FIXED)
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

  // 📊 STATS (ALREADY CORRECT, JUST CLEAN)
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

  // 🧺 WASHER
  Widget _washerCard() {
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

  // ignore: unused_element
  Widget _machineStreamCard({
    required String docId,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('machines')
          .doc(docId)
          .snapshots(),
      builder: (context, snapshot) {
        int available = 0;
        int total = 0;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          available = data['available'] ?? 0;
          total = data['total'] ?? 0;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _machineCard(
            title: title,
            subtitle: "$available of $total available",
            icon: icon,
            color: color,
            onTap: onTap,
          ),
        );
      },
    );
  }

  Widget _machineCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 36),
                const SizedBox(width: 12),
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
            const Icon(Icons.arrow_forward_ios, color: Colors.white),
          ],
        ),
      ),
    );
  }

  // ⬇️ BOTTOM NAV
  Widget _bottomNav() {
    return SizedBox(
      height: 80,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          /// BACKGROUND BAR
          Container(
            height: 60,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFB48DD6),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(navItems[0]),
                _navItem(navItems[1]),
                const SizedBox(width: 40), // center button space
                _navItem(navItems[2]),
                _navItem(navItems[3]),
              ],
            ),
          ),

          /// CENTER FLOATING HOME BUTTON
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: () {
                // already on Home
              },
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF8A3FFC),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.home,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 🔹 NAV ITEM
Widget _navItem(NavItem item) {
  return GestureDetector(
    onTap: item.onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(item.icon, color: Colors.white, size: 24),
        const SizedBox(height: 2),
        Text(
          item.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}
