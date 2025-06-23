import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final TextEditingController upiController = TextEditingController();
  User? user;
  bool isSubmitting = false;
  int userCoins = 0;
  bool isUserLoaded = false;

  final Color primary = const Color(0xFF7B1FA2);
  final Color lavenderBg = const Color(0xFFF3E5F5);

  @override
  void initState() {
    super.initState();
    initUserData();
  }

  Future<void> initUserData() async {
    user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      setState(() {
        userCoins = doc['coins'] ?? 0;
        isUserLoaded = true;
      });
    } else {
      setState(() => isUserLoaded = true);
    }
  }

  Future<void> requestWithdrawal(int coins, int amount) async {
    if (upiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid UPI ID')),
      );
      return;
    }

    if (userCoins < coins) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough coins')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final uid = user!.uid;

      await FirebaseFirestore.instance.collection('withdrawals').add({
        'uid': uid,
        'coins': coins,
        'amount': amount,
        'upiId': upiController.text,
        'timestamp': Timestamp.now(), // ensure timestamp always present
        'status': 'pending',
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'coins': FieldValue.increment(-coins)});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Withdrawal request submitted')),
      );
      await initUserData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Widget withdrawOption(String label, int coins, int amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => requestWithdrawal(coins, amount),
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 5,
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildWithdrawHistory() {
    if (user == null || !isUserLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('withdrawals')
          .where('uid', isEqualTo: user!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              "No withdrawals yet.",
              style: TextStyle(color: Colors.deepPurple, fontSize: 16),
            ),
          );
        }

        // Manually sort by timestamp descending
        docs.sort((a, b) {
          final aTime = (a['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          final bTime = (b['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          return bTime.compareTo(aTime);
        });

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;

            final upi = data['upiId'] ?? 'N/A';
            final amount = data['amount'] ?? 0;
            final coins = data['coins'] ?? 0;
            final status = (data['status'] ?? 'pending').toString().toUpperCase();

            Color statusColor = Colors.orange.shade100;
            if (status == 'APPROVED') statusColor = Colors.green.shade100;
            if (status == 'REJECTED') statusColor = Colors.red.shade100;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.deepPurple.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("₹$amount → $upi",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Coins: $coins",
                          style: const TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.w600)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lavenderBg.withOpacity(0.2),
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text("Withdraw Money"),
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Your Coins: $userCoins",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primary)),
            const SizedBox(height: 20),
            Text("Enter your UPI ID",
                style: TextStyle(fontSize: 16, color: primary)),
            const SizedBox(height: 8),
            TextField(
              controller: upiController,
              decoration: InputDecoration(
                hintText: "example@upi",
                filled: true,
                fillColor: Colors.white,
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            Text("Choose Withdrawal Amount",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primary)),
            const SizedBox(height: 12),
            if (isSubmitting)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  withdrawOption("₹10 for 1000 Coins", 1000, 10),
                  withdrawOption("₹50 for 5000 Coins", 5000, 50),
                  withdrawOption("₹100 for 10000 Coins", 10000, 100),
                ],
              ),
            const SizedBox(height: 30),
            const Divider(thickness: 1),
            const SizedBox(height: 10),
            Text("Withdrawal History",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primary)),
            const SizedBox(height: 10),
            buildWithdrawHistory(),
          ],
        ),
      ),
    );
  }
}
