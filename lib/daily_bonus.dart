import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DailyBonusScreen extends StatefulWidget {
  const DailyBonusScreen({super.key});

  @override
  State<DailyBonusScreen> createState() => _DailyBonusScreenState();
}

class _DailyBonusScreenState extends State<DailyBonusScreen> {
  bool isClaimed = false;
  bool isLoading = true;
  int userCoins = 0;
  DateTime? nextClaimTime;
  Duration timeLeft = Duration.zero;
  Timer? countdownTimer;
  int claimedDays = 0;
  DateTime? lastClaimDate;

  final List<int> rewards = [5, 10, 15, 20, 25, 30, 50];

  int get todayReward => claimedDays < rewards.length ? rewards[claimedDays] : rewards[0];

  @override
  void initState() {
    super.initState();
    checkBonusStatus();
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  void startCountdown() {
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      if (nextClaimTime != null && now.isBefore(nextClaimTime!)) {
        setState(() {
          timeLeft = nextClaimTime!.difference(now);
        });
      } else {
        countdownTimer?.cancel();
        setState(() {
          isClaimed = false;
          timeLeft = Duration.zero;
        });
      }
    });
  }

  Future<void> checkBonusStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null) {
        final lastClaim = data['lastBonusClaim'];
        claimedDays = data['claimedDays'] ?? 0;
        userCoins = data['coins'] ?? 0;

        if (lastClaim != null) {
          final lastDate = DateTime.parse(lastClaim.toString());
          lastClaimDate = lastDate;
          final now = DateTime.now();
          final next = lastDate.add(const Duration(hours: 24));

          if (now.difference(lastDate).inHours > 48) {
            claimedDays = 0;
            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'claimedDays': 0});
          } else if (now.isBefore(next)) {
            isClaimed = true;
            nextClaimTime = next;
            timeLeft = next.difference(now);
            startCountdown();
          }
        }
      }
    }
    setState(() => isLoading = false);
  }

  Future<void> claimBonus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !isClaimed) {
      final now = DateTime.now();

      if (lastClaimDate != null && now.difference(lastClaimDate!).inHours > 48) {
        claimedDays = 0;
      }

      claimedDays += 1;
      if (claimedDays > 7) claimedDays = 1;

      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await docRef.update({
        'coins': FieldValue.increment(rewards[claimedDays - 1]),
        'lastBonusClaim': now.toIso8601String(),
        'claimedDays': claimedDays,
      });

      await checkBonusStatus();

      setState(() {
        isClaimed = true;
        lastClaimDate = now;
        userCoins += rewards[claimedDays - 1];
        nextClaimTime = now.add(const Duration(hours: 24));
        timeLeft = const Duration(hours: 24);
      });

      startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You claimed your daily bonus of ${rewards[claimedDays - 1]} coins!")),
      );
    }
  }

  String formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = const Color(0xFF6A0DAD);
    final Color green = Colors.green;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F0FA),
      appBar: AppBar(
        title: const Text("🎁 Daily Bonus"),
        backgroundColor: primary,
        centerTitle: true,
        elevation: 4,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      "Your Balance",
                      style: TextStyle(color: Colors.grey[700], fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "$userCoins Coins",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: primary),
                    ),
                    const SizedBox(height: 20),
                    isClaimed
                        ? Column(
                      children: [
                        const Text("You've already claimed today's reward."),
                        const SizedBox(height: 8),
                        Text(
                          "Next bonus in: ${formatDuration(timeLeft)}",
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.deepPurple),
                        )
                      ],
                    )
                        : ElevatedButton.icon(
                      onPressed: claimBonus,
                      icon: const Icon(Icons.card_giftcard),
                      label: Text("Claim $todayReward Coins"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Weekly Rewards", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: 7,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final isClaimedDay = index < claimedDays;
                  return Container(
                    decoration: BoxDecoration(
                      color: isClaimedDay ? green.withOpacity(0.1) : primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isClaimedDay ? green : primary,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isClaimedDay ? Icons.check_circle : Icons.star,
                          color: isClaimedDay ? green : primary,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text("Day ${index + 1}"),
                        Text(
                          "+${rewards[index]}",
                          style: TextStyle(fontWeight: FontWeight.bold, color: isClaimedDay ? green : primary),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
