import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class EarnScreen extends StatefulWidget {
  const EarnScreen({super.key});

  @override
  State<EarnScreen> createState() => _EarnScreenState();
}

class _EarnScreenState extends State<EarnScreen> {
  String? referralCode;
  final TextEditingController _referralInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOrGenerateReferralCode();
  }

  Future<void> _loadOrGenerateReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    String? code = prefs.getString('referral_code');
    if (code == null) {
      code = _generateReferralCode();
      await prefs.setString('referral_code', code);
    }
    setState(() {
      referralCode = code;
    });
  }

  String _generateReferralCode() {
    final random = Random();
    final numbers = (100 + random.nextInt(900)).toString(); // 3 random digits
    final letter = String.fromCharCode(65 + random.nextInt(26)); // 1 random capital letter
    return "KAMAO$numbers$letter";
  }

  String _generateReferralCodeFromEmail(String email) {
    // Hash the email and take first 3 digits and 1 letter
    final hash = md5.convert(utf8.encode(email)).toString().toUpperCase();
    // Example: KAMAO + first 3 digits + first letter
    final numbers = hash.replaceAll(RegExp(r'[^0-9]'), '').substring(0, 3);
    final letter = hash.replaceAll(RegExp(r'[^A-Z]'), '').substring(0, 1);
    return "KAMAO$numbers$letter";
  }

  void _shareReferralCode(BuildContext context, String referralCode) {
    Clipboard.setData(ClipboardData(text: referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Referral code copied to clipboard!"),
        behavior: SnackBarBehavior.floating, // This makes it float
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), // Optional: adds margin
      ),
    );
  }

  void _claimCoins(BuildContext context) {
    final enteredCode = _referralInputController.text.trim();

    // 1. Check if empty
    if (enteredCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please enter a referral code."),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      );
      return;
    }

    // 2. Check if format is correct: KAMAO + 3 digits + 1 capital letter
    final codeRegExp = RegExp(r'^KAMAO\d{3}[A-Z]$');
    if (!codeRegExp.hasMatch(enteredCode)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Referral code format is wrong!"),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      );
      return;
    }

    // 3. Prevent using own code
    if (enteredCode == referralCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You cannot use your own referral code!"),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      );
      return;
    }

    // 4. (Optional) Prevent duplicate use: store used codes in SharedPreferences
    // For demonstration, let's check and store used codes
    _checkAndStoreUsedCode(context, enteredCode);
  }

  Future<void> _checkAndStoreUsedCode(BuildContext context, String code) async {
    final prefs = await SharedPreferences.getInstance();
    final usedCodes = prefs.getStringList('used_referral_codes') ?? [];
    if (usedCodes.contains(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("This referral code has already been used!"),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      );
      return;
    }
    usedCodes.add(code);
    await prefs.setStringList('used_referral_codes', usedCodes);

    // Success!
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Coins claimed!"),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text("Refer & Earn"),
        backgroundColor: Colors.blueAccent,
        elevation: 2,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.lightBlueAccent, Colors.blueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.share, size: 80, color: Colors.white),
                      const SizedBox(height: 20),
                      const Text(
                        "Invite your friends and earn rewards!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Share your referral code and both of you will get bonus coins.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          referralCode ?? "",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed:
                            () =>
                                _shareReferralCode(context, referralCode ?? ""),
                        icon: const Icon(Icons.send),
                        label: const Text("Share Code"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blueAccent,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        size: 60,
                        color: Colors.amber,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Claim Your Coins",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "You have coins to claim from referrals. Tap below to claim them now!",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Colors.black54),
                      ),
                      const SizedBox(height: 20),
                      // Add this TextField for referral code input
                      TextField(
                        controller: _referralInputController, // <-- Add this
                        decoration: InputDecoration(
                          labelText: "Enter Referral Code",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(Icons.code),
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
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
