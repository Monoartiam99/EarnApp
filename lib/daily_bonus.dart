import 'package:flutter/material.dart';

class DailyBonusScreen extends StatelessWidget {
  const DailyBonusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primary = Colors.deepPurpleAccent;
    final List<int> dailyRewards = [5, 10, 15, 20, 25, 30, 50];

    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      appBar: AppBar(
        title: const Text("🎉 Daily Bonus"),
        backgroundColor: primary,
        elevation: 2,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today, size: 70, color: Colors.deepPurple),
            const SizedBox(height: 20),
            const Text(
              "Claim your daily reward and keep the streak alive!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 30),

            // Daily Rewards Grid
            Expanded(
              child: GridView.builder(
                itemCount: dailyRewards.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: index == 0 ? Colors.green : Colors.deepPurpleAccent,
                        width: index == 0 ? 2.5 : 1.0,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Day ${index + 1}", style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text("+${dailyRewards[index]} Coins",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: index == 0 ? Colors.green : Colors.deepPurple,
                            )),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement bonus claim logic
              },
              icon: const Icon(Icons.card_giftcard),
              label: const Text("Claim Today's Bonus"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}