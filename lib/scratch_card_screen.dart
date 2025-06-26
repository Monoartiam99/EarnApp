import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scratcher/scratcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/services.dart';

class ScratchCardScreen extends StatefulWidget {
  const ScratchCardScreen({super.key});

  @override
  State<ScratchCardScreen> createState() => _ScratchCardScreenState();
}

class _ScratchCardScreenState extends State<ScratchCardScreen> {
  final Color deepBlue = const Color(0XFF7B1FA2);
  bool _revealed = false;
  int _reward = 0;
  int _scratchKey = DateTime.now().millisecondsSinceEpoch;

  int scratchCount = 0;
  String todayDate = "";
  final int maxScratchesPerDay = 10;

  RewardedAd? _rewardedAd;
  bool _isRewardedLoaded = false;

  @override
  void initState() {
    super.initState();
    MobileAds.instance.initialize();
    _generateReward();
    _loadRewardedAd();
    _fetchUserData();
  }

  void _generateReward() {
    final random = Random();
    _reward = 5 + random.nextInt(26); // 5–30 coins
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-8587580291187103/1477467655',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isRewardedLoaded = true;

          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isRewardedLoaded = false;
        },
      ),
    );
  }

  void _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month}-${now.day}";

      final lastDate = doc['lastScratchDate'] ?? "";
      final count = doc['scratchCount'] ?? 0;

      setState(() {
        todayDate = todayStr;
        scratchCount = (lastDate == todayStr) ? count : 0;
      });
    }
  }

  Future<void> _updateUserStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await docRef.update({
        'coins': FieldValue.increment(_reward),
        'scratchCount': FieldValue.increment(1),
        'lastScratchDate': todayDate,
      });
    }
  }

  void _resetCard() {
    if (scratchCount >= maxScratchesPerDay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You have used all 10 scratch cards today.")),
      );
      return;
    }

    setState(() {
      _revealed = false;
      _generateReward();
      _scratchKey = DateTime.now().millisecondsSinceEpoch;
    });
  }

  void _handleScratchCompletion() async {
    HapticFeedback.mediumImpact();
    setState(() => _revealed = true);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("🎉 Scratch Complete!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_circle_fill, color: Colors.deepPurple, size: 48),
            const SizedBox(height: 16),
            const Text(
              "Watch the ad to claim your coins!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showRewardedAd();
            },
            child: const Text("Watch Ad"),
          ),
        ],
      ),
    );
  }

  void _showRewardedAd() {
    if (_isRewardedLoaded && _rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) async {
          setState(() {
            scratchCount++;
          });
          await _updateUserStats();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("✅ +$_reward Coins added to your wallet!")),
          );
        },
      );
      _rewardedAd = null;
      _isRewardedLoaded = false;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ad not available. Please try again.")),
      );
    }
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = maxScratchesPerDay - scratchCount;

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
            Text(
              "Scratches Left Today: $remaining",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Scratcher(
              key: ValueKey(_scratchKey),
              brushSize: 40,
              threshold: 50,
              color: Colors.grey.shade400,
              onThreshold: scratchCount < maxScratchesPerDay ? _handleScratchCompletion : null,
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
                    BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4)),
                  ],
                  border: Border.all(color: Colors.white70, width: 2),
                ),
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _revealed
                      ? Column(
                    key: const ValueKey('revealed'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 38),
                      const SizedBox(height: 6),
                      Text(
                        "💰 $_reward Coins!",
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(blurRadius: 4, color: Colors.black54),
                            Shadow(blurRadius: 10, color: Colors.lightBlueAccent),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text("Lucky strike! 🚀",
                          style: TextStyle(color: Colors.white70, fontSize: 16)),
                    ],
                  )
                      : const Text(
                    "🎯 Scratch to Reveal!",
                    key: ValueKey('notRevealed'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            if (_revealed && scratchCount < maxScratchesPerDay)
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
