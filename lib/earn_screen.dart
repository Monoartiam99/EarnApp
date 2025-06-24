import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EarnScreen extends StatefulWidget {
  const EarnScreen({super.key});

  @override
  State<EarnScreen> createState() => _EarnScreenState();
}

class _EarnScreenState extends State<EarnScreen> {
  final _auth = FirebaseAuth.instance;
  String? referralCode;
  String? userEmail;
  final TextEditingController _referralInputController = TextEditingController();
  int walletCoins = 0;

  @override
  void initState() {
    super.initState();
    _loadUserAndReferralCode();
    _loadWalletCoins();
  }

  Future<void> _loadUserAndReferralCode() async {
    final user = _auth.currentUser;
    if (user != null) {
      final uid = user.uid;
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        userEmail = doc['email'];
        referralCode = _generateReferralCodeFromEmail(userEmail!);
        setState(() {});
      }
    }
  }

  String _generateReferralCodeFromEmail(String email) {
    final hash = md5.convert(utf8.encode(email)).toString().toUpperCase();
    final numbers = hash.replaceAll(RegExp(r'[^0-9]'), '').substring(0, 3);
    final letter = hash.replaceAll(RegExp(r'[^A-Z]'), '').substring(0, 1);
    return "KAMAO$numbers$letter";
  }

  Future<void> _loadWalletCoins() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      walletCoins = prefs.getInt('wallet_coins') ?? 0;
    });
  }

  Future<void> _addCoinsToWallet(int coins) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      walletCoins += coins;
    });
    await prefs.setInt('wallet_coins', walletCoins);
  }

  void _shareReferralCode(BuildContext context, String referralCode) {
    Clipboard.setData(ClipboardData(text: referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Referral code copied to clipboard!"),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    );
  }

  void _claimCoins(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyClaimed = prefs.getBool('coins_claimed') ?? false;
    if (alreadyClaimed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You have already claimed your coins!"),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      );
      return;
    }

    final enteredCode = _referralInputController.text.trim();
    if (enteredCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a referral code."),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      );
      return;
    }

    final codeRegExp = RegExp(r'^KAMAO\d{3}[A-Z]$');
    if (!codeRegExp.hasMatch(enteredCode)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Referral code format is wrong!"),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      );
      return;
    }

    if (enteredCode == referralCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You cannot use your own referral code!"),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      );
      return;
    }

    final usedCodes = prefs.getStringList('used_referral_codes') ?? [];
    if (usedCodes.contains(enteredCode)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This referral code has already been used!"),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      );
      return;
    }

    usedCodes.add(enteredCode);
    await prefs.setStringList('used_referral_codes', usedCodes);
    await prefs.setBool('coins_claimed', true);

    await _addCoinsToWallet(499);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Congratulations!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.monetization_on, color: Colors.amber, size: 48),
            SizedBox(height: 16),
            Text("+499 Coins", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
            SizedBox(height: 8),
            Text("Coins have been added to your wallet!"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("OK")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
        title: const Text("Refer & Earn"),
        backgroundColor: Colors.purpleAccent,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.share, size: 80, color: Colors.white),
                    const SizedBox(height: 20),
                    const Text("Invite your friends and earn rewards!",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 16),
                    const Text("Share your referral code and both of you will get bonus coins.",
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.white70)),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Text(referralCode ?? "Loading...",
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.blueAccent)),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: referralCode != null
                          ? () => _shareReferralCode(context, referralCode!)
                          : null,
                      icon: const Icon(Icons.send),
                      label: const Text("Share Code"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blueAccent,
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.monetization_on, size: 60, color: Colors.amber),
                    const SizedBox(height: 16),
                    const Text("Claim Your Coins",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                    const SizedBox(height: 10),
                    const Text("You have coins to claim from referrals. Tap below to claim them now!",
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.black54)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _referralInputController,
                      decoration: InputDecoration(
                        labelText: "Enter Referral Code",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.code),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _claimCoins(context),
                      icon: const Icon(Icons.card_giftcard),
                      label: const Text("Claim Coins"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
