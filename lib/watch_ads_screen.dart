import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WatchAdsScreen extends StatefulWidget {
  const WatchAdsScreen({super.key});

  @override
  State<WatchAdsScreen> createState() => _WatchAdsScreenState();
}

class _WatchAdsScreenState extends State<WatchAdsScreen> {
  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  void _loadAndShowAd() async {
    setState(() => _isLoading = true);

    print("🔄 Loading Rewarded Ad...");

    await RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917',
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
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({
                    'coins': FieldValue.increment(reward.amount.toInt()),
                  });
                  _showSnackBar("Coins added: ${reward.amount} 🎁");
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Watch Ads")),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
          onPressed: _loadAndShowAd,
          icon: const Icon(Icons.play_circle_outline),
          label: const Text("Watch Ad to Earn Reward"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}