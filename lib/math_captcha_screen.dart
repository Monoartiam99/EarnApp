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

  static const int rewardAmount = 10;

  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
    _loadRewardedAd();
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

    if (_rewardedAd == null || !_isAdLoaded) {
      setState(() {
        _message = 'Ad not available.';
      });
      return;
    }

    setState(() => _isLoading = true);

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
        try {
          final docRef = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid);
          await docRef.update({'coins': FieldValue.increment(rewardAmount)});

          setState(() {
            _message = '✅ Correct! +$rewardAmount Coins added.';
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
        title: const Text('🧠 Captcha Fill & Earn'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Solve to Earn Coins:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade700,
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
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Submit'),
              ),
              const SizedBox(height: 20),
              Text(
                _message,
                style: TextStyle(
                  fontSize: 18,
                  color: _message.startsWith('✅') ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}