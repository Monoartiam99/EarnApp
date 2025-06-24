import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final TextEditingController inputController = TextEditingController();
  User? user;
  bool isSubmitting = false;
  int userCoins = 0;
  bool isUserLoaded = false;
  String selectedMethod = 'UPI';

  final List<String> methods = ['UPI', 'Amazon Pay', 'Google Play'];

  @override
  void initState() {
    super.initState();
    initUserData();
  }

  Future<void> initUserData() async {
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .get();
      setState(() {
        userCoins = doc['coins'] ?? 0;
        isUserLoaded = true;
      });
    }
  }

  Future<void> requestWithdrawal(int coins, int amount) async {
    if (inputController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a valid ID')));
      return;
    }

    if (userCoins < coins) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Insufficient coins')));
      return;
    }

    setState(() => isSubmitting = true);
    try {
      final uid = user!.uid;
      await FirebaseFirestore.instance.collection('withdrawals').add({
        'uid': uid,
        'coins': coins,
        'amount': amount,
        'upiId': inputController.text.trim(),
        'timestamp': Timestamp.now(),
        'status': 'pending',
        'method': selectedMethod,
      });

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'coins': FieldValue.increment(-coins),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Withdrawal request submitted')),
      );
      inputController.clear();
      await initUserData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Widget methodSelector() {
    return Wrap(
      spacing: 8,
      children:
          methods.map((method) {
            final bool selected = selectedMethod == method;
            return ChoiceChip(
              label: Text(method),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  selectedMethod = method;
                  inputController.clear();
                });
              },
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: Colors.white,
              selectedColor: Colors.deepPurple,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            );
          }).toList(),
    );
  }

  Widget withdrawButton(String label, int coins, int amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed:
              isSubmitting ? null : () => requestWithdrawal(coins, amount),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget historyCard(Map<String, dynamic> data) {
    final status = (data['status'] ?? 'pending').toString().toUpperCase();
    final method = data['method'] ?? 'UPI';
    final id = data['upiId'] ?? 'N/A';
    final coins = data['coins'] ?? 0;
    final amount = data['amount'] ?? 0;

    Color badgeColor = Colors.orangeAccent;
    if (status == 'APPROVED') badgeColor = Colors.green;
    if (status == 'REJECTED') badgeColor = Colors.redAccent;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.deepPurple.shade100),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "₹$amount → $id ($method)",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Coins: $coins",
                style: const TextStyle(color: Colors.deepPurple),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget withdrawalHistory() {
    if (user == null || !isUserLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('withdrawals')
              .where('uid', isEqualTo: user!.uid)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Text(
            "No withdrawals yet.",
            style: TextStyle(color: Colors.grey),
          );
        }

        docs.sort((a, b) {
          final aTime =
              (a['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          final bTime =
              (b['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          return bTime.compareTo(aTime);
        });

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: historyCard(docs[index].data() as Map<String, dynamic>),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        title: const Text("Withdraw Money"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your Coins: $userCoins",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Choose Method",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            methodSelector(),
            const SizedBox(height: 20),

            Text(
              selectedMethod == "Google Play"
                  ? "Enter Google Email"
                  : "Enter UPI ID",
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: inputController,
              decoration: InputDecoration(
                hintText:
                    selectedMethod == "Google Play"
                        ? "example@gmail.com"
                        : "example@upi",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Select Withdrawal Amount",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (isSubmitting)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  withdrawButton("₹10 for 1000 Coins", 1000, 10),
                  withdrawButton("₹50 for 5000 Coins", 5000, 50),
                  withdrawButton("₹100 for 10000 Coins", 10000, 100),
                ],
              ),

            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              "Withdrawal History",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            withdrawalHistory(),
          ],
        ),
      ),
    );
  }
}
