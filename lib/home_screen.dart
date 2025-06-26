import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'auth_screen.dart';
import 'scratch_card_screen.dart';
import 'spin_wheel_screen.dart';
import 'daily_bonus.dart';
import 'watch_ads_screen.dart'; // ✅ Added this import
import 'profile_screen.dart';
import 'earn_screen.dart';
import 'withdraw_screen.dart';
import 'math_captcha_screen.dart';
import 'promo_code_screen.dart'; // ✅ add this



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int userCoins = 0;
  String userName = "User";
  int walletCoins = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _loadWalletCoins();
  }

  void _fetchUserData() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((doc) {
            if (doc.exists) {
              setState(() {
                userName = doc['name'] ?? "User";
                userCoins = doc['coins'] ?? 0;
              });
            }
          });
    }
  }

  Future<void> _loadWalletCoins() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      walletCoins = prefs.getInt('wallet_coins') ?? 0;
    });
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Confirm Logout"),
            content: const Text("Are you sure you want to log out?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthScreen()),
                  );
                },
                child: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 4,
        title: const Text(
          "Kamao Money 💰",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.deepPurple),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 48,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Home
            const ListTile(leading: Icon(Icons.home), title: Text('Home')),
            // Refer & Earn
            ListTile(
              leading: const Icon(Icons.share, color: Colors.deepPurple),
              title: const Text('Refer & Earn'),
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => EarnScreen()));
              },
            ),
            // Withdraw
            ListTile(
              leading: const Icon(
                Icons.account_balance_wallet,
                color: Colors.deepPurple,
              ),
              title: const Text('Withdraw'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => WithdrawScreen()),
                );
              },
            ),
            // --- Add these for social media ---
            const Divider(),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.instagram, color: Colors.pink),
              title: const Text('Instagram'),
              onTap: () async {
                const url = 'https://www.instagram.com/kamao_money_official?igsh=bXV4bXAwdndoMDMz';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  );
                }
              },
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.telegram, color: Colors.blue),
              title: const Text('Telegram'),
              onTap: () async {
                const url = 'https://t.me/kamao_money_official';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  );
                }
              },
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.youtube, color: Colors.red),
              title: const Text('YouTube'),
              onTap: () async {
                const url = 'https://youtube.com/@kamao_money_official?si=iUhNc6P-yMfQyW7m';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  );
                }
              },
            ),
            // ...rest of your Drawer...
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildUserInfo(context),
              const SizedBox(height: 20),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purpleAccent.shade700, Colors.deepPurple.shade400],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurpleAccent.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              "Hi $userName 👋",
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder:
                    (ctx) => AlertDialog(
                      title: Row(
                        children: const [
                          Icon(
                            Icons.account_balance_wallet,
                            color: Colors.deepPurpleAccent,
                          ),
                          SizedBox(width: 8),
                          Text("Wallet Balance"),
                        ],
                      ),
                      content: Text(
                        "$userCoins Coins",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("Close"),
                        ),
                      ],
                    ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Colors.yellowAccent,
                size: 30,
              ),
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
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
        children: [

          _buildEarningBox(
            context,
            "Daily Bonus",
            Icons.stars,
            Colors.deepPurple,
            const DailyBonusScreen(),
          ),


          _buildEarningBox(
            context,
            "Scratch Card",
            Icons.card_giftcard,
            Colors.deepPurple,
            const ScratchCardScreen(),
          ),
          _buildEarningBox(
            context,
            "Spin & Win",
            Icons.rotate_right,
            Colors.deepPurple,
            const SpinWheelScreen(),
          ),
          _buildEarningBox(
            context,
            "Watch Ads",
            Icons.video_collection,
            Colors.deepPurple,
            const WatchAdsScreen(),
          ),
          _buildEarningBox(
            context,
            "Promo Code",
            Icons.discount,
            Colors.deepPurple,
            const PromoCodeScreen(),
          ),

          _buildEarningBox(
            context,
            "Captcha Earn",
            Icons.calculate_outlined,
            Colors.deepPurple,
            const MathCaptchaScreen(),
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
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
