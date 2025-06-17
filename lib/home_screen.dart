import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_screen.dart';
import 'scratch_card_screen.dart';
import 'spin_wheel_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int userCoins = 0;
  String userName = "User";

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().listen((doc) {
        if (doc.exists) {
          setState(() {
            userName = doc['name'] ?? "User";
            userCoins = doc['coins'] ?? 0;
          });
        }
      });
    }
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Confirm Logout"),
        content: Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AuthScreen()),
              );
            },
            child: Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        elevation: 4,
        title: Text(
          "Kamao Money 💰",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildUserInfo(context),
              SizedBox(height: 20),
              _buildEarningsBoxes(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blueAccent.shade700, Colors.lightBlueAccent]),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              "Hi $userName 👋",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.account_balance_wallet, color: Colors.blueAccent),
                      SizedBox(width: 8),
                      Text("Wallet Balance"),
                    ],
                  ),
                  content: Text(
                    "$userCoins Coins",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Close")),
                  ],
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.account_balance_wallet, color: Colors.yellowAccent, size: 30),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsBoxes(BuildContext context) {
    return SizedBox(
      height: 600,
      child: GridView.count(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
        children: [
          _buildEarningBox(context, "Scratch Card", Icons.card_giftcard, Colors.blueAccent, ScratchCardScreen()),
          _buildEarningBox(context, "Spin & Win", Icons.rotate_right, Colors.blueAccent, SpinWheelScreen()),
          _buildEarningBox(context, "Watch Ads", Icons.video_collection, Colors.blueAccent, null),
          _buildEarningBox(context, "Promo Code", Icons.discount, Colors.blueAccent, null),
          _buildEarningBox(context, "Daily Bonus", Icons.stars, Colors.blueAccent, null),
        ],
      ),
    );
  }

  Widget _buildEarningBox(BuildContext context, String title, IconData icon, Color color, Widget? page) {
    return GestureDetector(
      onTap: () {
        if (page != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => page));
        }
      },
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            SizedBox(height: 12),
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  static String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning";
    } else if (hour < 18) {
      return "Good Afternoon";
    } else {
      return "Good Evening";
    }
  }
}