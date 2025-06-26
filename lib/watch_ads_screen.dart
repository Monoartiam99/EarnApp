import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class WatchAdsScreen extends StatefulWidget {
  const WatchAdsScreen({super.key});

  @override
  State<WatchAdsScreen> createState() => _WatchAdsScreenState();
}

class _WatchAdsScreenState extends State<WatchAdsScreen> {
  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  int _adsWatched = 0;
  final int _maxAdsPerDay = 10;

  @override
  void initState() {
    super.initState();
    _initializeAdCounter();
  }

  Future<void> _initializeAdCounter() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await docRef.get();

    if (snapshot.exists) {
      final data = snapshot.data()!;
      final lastDate = data['lastAdWatchDate'] ?? today;
      if (lastDate != today) {
        await docRef.update({
          'rewardedAdsWatched': 0,
          'lastAdWatchDate': today,
        });
        setState(() => _adsWatched = 0);
      } else {
        setState(() => _adsWatched = data['rewardedAdsWatched'] ?? 0);
      }
    } else {
      await docRef.set({
        'coins': 0,
        'rewardedAdsWatched': 0,
        'lastAdWatchDate': today,
      });
      setState(() => _adsWatched = 0);
    }
  }

  Future<void> _loadAndShowAd() async {
    if (_adsWatched >= _maxAdsPerDay) {
      _showSnackBar("You've reached today's ad limit 🎯");
      return;
    }

    setState(() => _isLoading = true);
    print("🔄 Loading Rewarded Ad...");

    await RewardedAd.load(
      adUnitId: 'ca-app-pub-8587580291187103/4322558198',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print("✅ Ad loaded successfully");
          _rewardedAd = ad;

          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              print("ℹ️ Ad dismissed");
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _rewardedAd = null;
              print("❌ Failed to show ad: $error");
              _showSnackBar("Ad failed to display");
            },
          );

          _rewardedAd!.show(
            onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
              print("🎉 User earned reward: ${reward.amount} ${reward.type}");

              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                try {
                  final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
                  await docRef.update({
                    'coins': FieldValue.increment(reward.amount.toInt()),
                    'rewardedAdsWatched': FieldValue.increment(1),
                    'lastAdWatchDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                  });
                  _showSnackBar("Coins added: ${reward.amount} 🎁");
                  setState(() => _adsWatched += 1);
                } catch (e) {
                  print("🔥 Failed to update coins: $e");
                  _showSnackBar("Failed to add coins");
                }
              } else {
                _showSnackBar("User not logged in");
              }
            },
          );

          setState(() => _isLoading = false);
        },
        onAdFailedToLoad: (error) {
          print("❌ Failed to load ad: $error");
          _rewardedAd = null;
          setState(() => _isLoading = false);
          _showSnackBar("Failed to load ad");
        },
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _maxAdsPerDay - _adsWatched;

    return Scaffold(
      appBar: AppBar(title: const Text("Watch Ads")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Watched $_adsWatched of $_maxAdsPerDay ads today",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
              onPressed: remaining > 0 ? _loadAndShowAd : null,
              icon: const Icon(Icons.play_circle_outline),
              label: Text(remaining > 0
                  ? "Watch Ad to Earn Reward"
                  : "Daily Limit Reached"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}