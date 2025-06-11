import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpinWheelScreen extends StatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen> {
  final List<int> coinOptions = [10, 20, 30, 40, 50];
  final StreamController<int> _controller = StreamController<int>();
  int _totalCoins = 0;
  int? _reward;
  int? _selectedIndex;
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();
    _loadTotalCoins();
  }

  Future<void> _loadTotalCoins() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _totalCoins = prefs.getInt('totalCoins') ?? 0;
    });
  }

  Future<void> _updateTotalCoins() async {
    final prefs = await SharedPreferences.getInstance();
    _totalCoins += _reward ?? 0;
    await prefs.setInt('totalCoins', _totalCoins);
  }

  void _spinWheel() {
    if (_isSpinning) return;

    final index = Random().nextInt(coinOptions.length);
    _selectedIndex = index;
    _controller.add(index);
    setState(() {
      _isSpinning = true;
    });
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color deepBlue = Color(0xFF0D47A1);
    const Color gradientStart = Color(0xFF1E3A8A);
    const Color gradientEnd = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      appBar: AppBar(
        backgroundColor: deepBlue,
        title: const Text("Spin & Win", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Total Coins: $_totalCoins",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [gradientStart, gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 320,
                width: 320,
                child: FortuneWheel(
                  selected: _controller.stream,
                  animateFirst: false,
                  items: coinOptions.map(
                        (value) => FortuneItem(
                      child: Text(
                        "$value Coins",
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      style: FortuneItemStyle(
                        color: Colors.accents[Random().nextInt(Colors.accents.length)].shade400,
                        borderColor: Colors.white,
                        borderWidth: 2,
                      ),
                    ),
                  ).toList(),
                  onAnimationEnd: () {
                    if (_selectedIndex != null) {
                      setState(() {
                        _reward = coinOptions[_selectedIndex!];
                        _isSpinning = false;
                      });
                      _updateTotalCoins();
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
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _spinWheel,
              icon: const Icon(Icons.casino),
              label: const Text("SPIN NOW"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
            ),
            const SizedBox(height: 30),
            if (_reward != null)
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 500),
                child: Text(
                  "🎉 You won $_reward Coins!",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellowAccent,
                    shadows: [
                      Shadow(blurRadius: 10, color: Colors.black87),
                      Shadow(blurRadius: 15, color: Colors.orangeAccent),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}