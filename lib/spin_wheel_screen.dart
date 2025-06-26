import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class SpinWheelScreen extends StatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  _SpinWheelScreenState createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen> {
  final List<int> coinOptions = [5, 8, 10, 17, 30];
  final StreamController<int> _controller = StreamController<int>();
  int userCoins = 0;
  int spinCount = 0;
  String? lastSpinDate;
  final int maxSpinsPerDay = 10;
  int? _reward;
  int? _selectedIndex;
  bool _isSpinning = false;

  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;

  @override
  void initState() {
    super.initState();
    MobileAds.instance.initialize();
    _fetchUserData();
    _loadRewardedAd();
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-8587580291187103/1028528058',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;

          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isRewardedAdLoaded = false;
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isRewardedAdLoaded = false;
              _loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdLoaded = false;
        },
      ),
    );
  }

  void _fetchUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().listen((doc) {
        if (doc.exists) {
          final today = DateTime.now();
          final todayStr = "${today.year}-${today.month}-${today.day}";
          final savedDate = doc['lastSpinDate'] ?? "";
          setState(() {
            userCoins = doc['coins'] ?? 0;
            spinCount = (savedDate == todayStr) ? (doc['spinCount'] ?? 0) : 0;
            lastSpinDate = todayStr;
          });
        }
      });
    }
  }

  Future<void> _updateUserCoins() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _reward != null) {
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final today = DateTime.now();
      final todayStr = "${today.year}-${today.month}-${today.day}";
      await docRef.update({
        'coins': FieldValue.increment(_reward!),
        'spinCount': FieldValue.increment(1),
        'lastSpinDate': todayStr,
      });
    }
  }

  void _spinWheel() {
    if (_isSpinning) return;
    if (spinCount >= maxSpinsPerDay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You have reached your daily spin limit!")),
      );
      return;
    }

    final index = Random().nextInt(coinOptions.length);
    _selectedIndex = index;
    _controller.add(index);
    setState(() {
      _isSpinning = true;
      _reward = null;
    });
  }

  void _showRewardedAd() {
    if (_isRewardedAdLoaded && _rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) async {
          await _updateUserCoins();
        },
      );
      _rewardedAd = null;
      _isRewardedAdLoaded = false;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ad not loaded yet. Please try again.")),
      );
    }
  }

  @override
  void dispose() {
    _controller.close();
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 157, 42, 196),
        title: const Text("Spin & Win", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Wallet Balance: $userCoins Coins",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange)),
                  const SizedBox(height: 12),
                  Text("Spins left today: ${maxSpinsPerDay - spinCount}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 20),
                  _buildWheelContainer(),
                  const SizedBox(height: 40),
                  _buildSpinButton(),
                  const SizedBox(height: 30),
                  if (_reward != null) _buildRewardMessage(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWheelContainer() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color.fromARGB(255, 129, 21, 162), Colors.lightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 320,
        width: 320,
        child: FortuneWheel(
          selected: _controller.stream,
          animateFirst: false,
          items: coinOptions.map((value) {
            return FortuneItem(
              child: Text(
                "$value Coins",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              style: FortuneItemStyle(
                color: Colors.accents[Random().nextInt(Colors.accents.length)].shade400,
                borderColor: Colors.white,
                borderWidth: 2,
              ),
            );
          }).toList(),
          onAnimationEnd: () {
            if (_selectedIndex != null) {
              setState(() {
                _reward = coinOptions[_selectedIndex!];
                _isSpinning = false;
              });
              _showRewardedAd(); // show ad after wheel animation
            }
          },
          indicators: const [
            FortuneIndicator(
              alignment: Alignment.topCenter,
              child: TriangleIndicator(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpinButton() {
    return ElevatedButton.icon(
      onPressed: _spinWheel,
      icon: const Icon(Icons.sports_esports, size: 28),
      label: const Text("SPIN NOW"),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 219, 41, 255),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
      ),
    );
  }

  Widget _buildRewardMessage() {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 500),
      child: Text(
        "🎉 You won $_reward Coins!",
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Colors.redAccent,
          shadows: [
            Shadow(blurRadius: 10, color: Colors.black87),
            Shadow(blurRadius: 15, color: Colors.orangeAccent),
          ],
        ),
      ),
    );
  }
}
