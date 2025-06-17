import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scratcher/scratcher.dart';

class ScratchCardScreen extends StatefulWidget {
  const ScratchCardScreen({super.key});

  @override
  State<ScratchCardScreen> createState() => _ScratchCardScreenState();
}

class _ScratchCardScreenState extends State<ScratchCardScreen> {
  final Color deepBlue = const Color(0xFF0D47A1);
  final Color brightBlue = const Color(0xFF42A5F5);

  bool _revealed = false;
  int _reward = 0;
  int _scratchKey = DateTime.now().millisecondsSinceEpoch;

  void _generateReward() {
    final random = Random();
    _reward = 10 + random.nextInt(41); // ₹10–₹50
  }

  @override
  void initState() {
    super.initState();
    _generateReward();
  }

  Future<void> _updateUserCoins() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userDoc.update({
        'coins': FieldValue.increment(_reward),
      });
    }
  }

  void _resetCard() {
    setState(() {
      _revealed = false;
      _generateReward();
      _scratchKey = DateTime.now().millisecondsSinceEpoch;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      appBar: AppBar(
        backgroundColor: deepBlue,
        title: const Text("✨ Scratch & Win", style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 2,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Scratcher(
              key: ValueKey(_scratchKey),
              brushSize: 40,
              threshold: 50,
              color: Colors.grey.shade400,
              onThreshold: () {
                setState(() => _revealed = true);
                _updateUserCoins(); // Update Firestore when revealed
              },
              child: Container(
                height: 240,
                width: 330,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, brightBlue.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: deepBlue.withOpacity(0.6), width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _revealed
                      ? Column(
                    key: const ValueKey('revealed'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "🎉 $_reward Coins!",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: _reward == 50 ? Colors.blue : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "You crushed it! 🚀",
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ],
                  )
                      : const Text(
                    "🎯 Scratch to Reveal!",
                    key: ValueKey('notRevealed'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            if (_revealed)
              ElevatedButton.icon(
                onPressed: _resetCard,
                icon: const Icon(Icons.replay),
                label: const Text("Try Again"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: deepBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}