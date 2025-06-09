import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_screen.dart';
import 'scratch_card_screen.dart';
import 'spin_wheel_screen.dart';

class HomeScreen extends StatelessWidget {
  final int userCoins = 120050; // Example balance in coins (₹1200.50)
  final String userName = "Ujjwal"; // Replace with dynamic user name
  // Personalized greeting based on time
  String get greeting => _getGreeting();

  const HomeScreen({super.key});

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        title: Text(
          "Kamao Money 💰",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildUserInfo(),
              SizedBox(height: 20),
              _buildEarningsBoxes(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent, Colors.lightBlueAccent],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Flexible(
            child: Text(
              "Hi $userName 👋", // Only "Hi Ujjwal"
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 10),
          Icon(Icons.monetization_on, color: Colors.yellowAccent),
          SizedBox(width: 4),
          Text(
            " $userCoins Coins",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsBoxes(BuildContext context) {
    return SizedBox(
      height: 600, // Adjust height as needed for your content/screen
      child: GridView.count(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        crossAxisCount: 2,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        childAspectRatio: 1.2,
        children: [
          _buildEarningBox(
            context,
            "Scratch Card",
            Icons.card_giftcard,
            Colors.blue,
            ScratchCardScreen(),
          ),
          _buildEarningBox(
            context,
            "Spin & Win",
            Icons.casino, // Use a built-in icon similar to a spin wheel
            Colors.blue,
            SpinWheelScreen(),
          ),
          _buildEarningBox(
            context,
            "Watch Ads",
            Icons.video_collection,
            Colors.blue,
            null,
          ),
          _buildEarningBox(
            context,
            "Promo Code",
            Icons.discount,
            Colors.blue,
            null,
          ),
          _buildEarningBox(
            context,
            "Daily Bonus",
            Icons.stars,
            Colors.blue,
            null,
          ),
          _buildEarningBox(
            context,
            "Leaderboard",
            Icons.leaderboard,
            Colors.blue,
            null,
          ),
        ],
      ),
    );
  }

  Widget _buildEarningBox(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Widget? page,
  ) {
    return GestureDetector(
      onTap: () {
        if (page != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        }
      },
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 45, color: color),
            SizedBox(height: 9),
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
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
