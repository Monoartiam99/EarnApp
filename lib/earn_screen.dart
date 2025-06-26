import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EarnScreen extends StatefulWidget {
  const EarnScreen({super.key});

  @override
  State<EarnScreen> createState() => _EarnScreenState();
}

class _EarnScreenState extends State<EarnScreen> {
  final _auth = FirebaseAuth.instance;
  final TextEditingController _referralInputController = TextEditingController();

  String? referralCode;
  String? userEmail;
  int walletCoins = 0;
  bool isCreatingCode = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      final uid = user.uid;
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        userEmail = doc['email'];
        referralCode = doc.data()!.containsKey('referralCode') ? doc['referralCode'] : null;
        walletCoins = doc['coins'] ?? 0;
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

  Future<void> _createReferralCode() async {
    if (userEmail == null) return;
    final user = _auth.currentUser;
    if (user == null) return;

    final code = _generateReferralCodeFromEmail(userEmail!);

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'referralCode': code,
    });

    setState(() {
      referralCode = code;
    });
  }

  Future<void> _claimCoins(BuildContext context) async {
    final enteredCode = _referralInputController.text.trim();

    if (enteredCode.isEmpty || referralCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please enter a valid referral code."),
      ));
      return;
    }

    if (enteredCode == referralCode) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("You cannot use your own referral code."),
      ));
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (userDoc.data()?['hasClaimedReferral'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("You have already claimed referral reward."),
      ));
      return;
    }

    final referredUserQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('referralCode', isEqualTo: enteredCode)
        .get();

    if (referredUserQuery.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Invalid referral code."),
      ));
      return;
    }

    // Reward both users
    final referredUser = referredUserQuery.docs.first;
    final referredUserId = referredUser.id;

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final referredRef = FirebaseFirestore.instance.collection('users').doc(referredUserId);

      transaction.update(userRef, {
        'coins': FieldValue.increment(499),
        'hasClaimedReferral': true,
      });

      transaction.update(referredRef, {
        'coins': FieldValue.increment(499),
      });
    });

    setState(() {
      walletCoins += 499;
    });

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Success"),
        content: const Text("499 coins added to your wallet and to the referrer!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _shareReferralCode(BuildContext context) {
    if (referralCode != null) {
      Clipboard.setData(ClipboardData(text: referralCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Referral code copied!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Refer & Earn"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (referralCode == null)
                ElevatedButton(
                  onPressed: isCreatingCode
                      ? null
                      : () async {
                    setState(() => isCreatingCode = true);
                    await _createReferralCode();
                    setState(() => isCreatingCode = false);
                  },
                  child: const Text("Create Referral Code"),
                )
              else
                Column(
                  children: [
                    Text(
                      "Your Referral Code",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        referralCode!,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _shareReferralCode(context),
                      icon: const Icon(Icons.copy),
                      label: const Text("Copy Code"),
                    ),
                  ],
                ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              const Text("Claim Referral Coins"),
              const SizedBox(height: 8),
              TextField(
                controller: _referralInputController,
                decoration: const InputDecoration(
                  labelText: "Enter Referral Code",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _claimCoins(context),
                child: const Text("Claim 499 Coins"),
              ),
              const SizedBox(height: 24),
              Text("Your Total Coins: $walletCoins",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
