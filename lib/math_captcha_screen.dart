import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class MathCaptchaScreen extends StatefulWidget {
  const MathCaptchaScreen({super.key});

  @override
  State<MathCaptchaScreen> createState() => _MathCaptchaScreenState();
}

class _MathCaptchaScreenState extends State<MathCaptchaScreen> {
  int _num1 = 0;
  int _num2 = 0;
  final TextEditingController _controller = TextEditingController();
  String _message = '';
  bool _isLoading = false;
  int _dailyCount = 0;

  static const int rewardAmount = 10;
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
    _loadRewardedAd();
    _fetchDailyCount(); // Load count on init
  }

  void _generateCaptcha() {
    final rand = Random();
    _num1 = 1 + rand.nextInt(20);
    _num2 = 1 + rand.nextInt(20);
    _controller.clear();
    _message = '';
    setState(() {});
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-8587580291187103/7272719812',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdLoaded = true;
        },
        onAdFailedToLoad: (error) {
          _isAdLoaded = false;
        },
      ),
    );
  }

  Future<void> _fetchDailyCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await docRef.get();
    final data = snapshot.data() ?? {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime? lastDate;

    if (data['lastCaptchaDate'] != null) {
      lastDate = DateTime.tryParse(data['lastCaptchaDate']);
    }

    int dailyCount = data['dailyCaptchaCount'] ?? 0;

    if (lastDate == null || lastDate.isBefore(today)) {
      dailyCount = 0;
      await docRef.update({
        'lastCaptchaDate': today.toIso8601String(),
        'dailyCaptchaCount': 0,
      });
    }

    setState(() {
      _dailyCount = dailyCount;
    });
  }

  Future<void> _submitAnswer() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final answer = int.tryParse(_controller.text.trim());
    if (answer == null || answer != _num1 + _num2) {
      setState(() {
        _message = '❌ Incorrect! Try again.';
      });
      return;
    }

    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await docRef.get();
    final data = snapshot.data() ?? {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime? lastDate;

    if (data['lastCaptchaDate'] != null) {
      lastDate = DateTime.tryParse(data['lastCaptchaDate']);
    }

    int dailyCount = data['dailyCaptchaCount'] ?? 0;

    if (lastDate == null || lastDate.isBefore(today)) {
      dailyCount = 0;
      await docRef.update({
        'lastCaptchaDate': today.toIso8601String(),
        'dailyCaptchaCount': 0,
      });
    }

    if (dailyCount >= 10) {
      setState(() => _message = '🔒 Daily limit reached. Try again tomorrow!');
      return;
    }

    if (_rewardedAd == null || !_isAdLoaded) {
      setState(() {
        _message = '⚠️ Ad not available. Please try again shortly.';
      });
      return;
    }

    setState(() => _isLoading = true);

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) async {
        try {
          await docRef.update({
            'coins': FieldValue.increment(rewardAmount),
            'dailyCaptchaCount': FieldValue.increment(1),
          });

          setState(() {
            _message = '✅ Correct! +$rewardAmount Coins added.';
            _dailyCount += 1;
          });

          Future.delayed(const Duration(seconds: 2), _generateCaptcha);
        } catch (e) {
          setState(() => _message = '⚠️ Error updating coins.');
        }
      },
    );

    _rewardedAd = null;
    _isAdLoaded = false;
    _loadRewardedAd();

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      appBar: AppBar(
        title: const Text('Captcha Fill & Earn'),
        backgroundColor: Color(0xFFA15FFF), // Light purple shade
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Solve to Earn Coins',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Solved: $_dailyCount / 10 today',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.deepPurple.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '$_num1 + $_num2 = ?',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Enter your answer',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                    onPressed: _submitAnswer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _message,
                    style: TextStyle(
                      fontSize: 18,
                      color: _message.startsWith('✅')
                          ? Colors.green
                          : _message.startsWith('⚠️') || _message.startsWith('🔒')
                          ? Colors.orange
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}