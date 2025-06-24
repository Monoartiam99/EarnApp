import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scratcher/scratcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/services.dart'; // For haptic feedback

class ScratchCardScreen extends StatefulWidget {
  const ScratchCardScreen({super.key});

  @override
  State<ScratchCardScreen> createState() => _ScratchCardScreenState();
}

class _ScratchCardScreenState extends State<ScratchCardScreen> {
  final Color deepBlue = const Color(0XFF7B1FA2);
  final Color brightBlue = const Color(0XFF7B1FA2);

  bool _revealed = false;
  int _reward = 0;
  int _scratchKey = DateTime.now().millisecondsSinceEpoch;

  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    MobileAds.instance.initialize();
    _generateReward();
    _loadRewardedAd();
  }

  void _generateReward() {
    final random = Random();
    _reward = 10 + random.nextInt(41); // ₹10–₹50
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isAdLoaded = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isAdLoaded = false;
        },
      ),
    );
  }

  Future<void> _updateUserCoins() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      await userDoc.update({'coins': FieldValue.increment(_reward)});
    }
  }

  void _resetCard() {
    setState(() {
      _revealed = false;
      _generateReward();
      _scratchKey = DateTime.now().millisecondsSinceEpoch;
    });
  }

  void _showAd() {
    if (_isAdLoaded && _rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {},
      );
      _rewardedAd = null;
      _isAdLoaded = false;
      _loadRewardedAd();
    }
  }

  void _handleScratchCompletion() async {
    HapticFeedback.mediumImpact();
    setState(() => _revealed = true);
    await _updateUserCoins();
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("🎉 Congratulations!"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: Colors.amber,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  "+$_reward Coins",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                const Text("Coins have been added to your wallet!"),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
    );
    _showAd();
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      appBar: AppBar(
        backgroundColor: deepBlue,
        title: const Text(
          "✨ Scratch & Win",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
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
              onThreshold: _handleScratchCompletion,
              child: Container(
                height: 240,
                width: 330,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0XFF7B1FA2), Color(0xFF42A5F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.white70, width: 2),
                ),
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child:
                      _revealed
                          ? Column(
                            key: const ValueKey('revealed'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 38,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "💰 $_reward Coins!",
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4,
                                      color: Colors.black54,
                                    ),
                                    Shadow(
                                      blurRadius: 10,
                                      color: Colors.lightBlueAccent,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Lucky strike! 🚀",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          )
                          : const Text(
                            "🎯 Scratch to Reveal!",
                            key: ValueKey('notRevealed'),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(blurRadius: 4, color: Colors.black54),
                              ],
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
