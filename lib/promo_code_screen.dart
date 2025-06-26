import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PromoCodeScreen extends StatefulWidget {
  const PromoCodeScreen({super.key});

  @override
  State<PromoCodeScreen> createState() => _PromoCodeScreenState();
}

class _PromoCodeScreenState extends State<PromoCodeScreen> {
  final _claimCodeController = TextEditingController();
  final _createCodeController = TextEditingController();
  final _createCoinsController = TextEditingController();
  final _createMaxClaimsController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _message = "";

  Future<void> _claimPromoCode() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final code = _claimCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _message = "⚠️ Please enter a promo code.");
      return;
    }

    final docRef = _firestore.collection('promo_codes').doc(code);
    final doc = await docRef.get();

    if (!doc.exists) {
      setState(() => _message = "❌ Promo code not found.");
      return;
    }

    final data = doc.data()!;
    final int claims = data['claims'] ?? 0;
    final int maxClaims = data['maxClaims'] ?? 0;
    final List<dynamic> claimedBy = data['claimedBy'] ?? [];

    if (claims >= maxClaims) {
      setState(() => _message = "🚫 Promo code has expired.");
      return;
    }

    if (claimedBy.contains(user.uid)) {
      setState(() => _message = "⚠️ You’ve already used this code.");
      return;
    }

    final int coins = data['coins'] ?? 0;
    final userDoc = _firestore.collection('users').doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final freshDoc = await transaction.get(docRef);
      final freshClaims = freshDoc['claims'] ?? 0;
      final freshClaimedBy = List<String>.from(freshDoc['claimedBy'] ?? []);

      if (freshClaims >= maxClaims) throw Exception("Max claims reached");
      if (freshClaimedBy.contains(user.uid)) throw Exception("Already claimed");

      transaction.update(docRef, {
        'claims': freshClaims + 1,
        'claimedBy': FieldValue.arrayUnion([user.uid]),
      });

      transaction.update(userDoc, {
        'coins': FieldValue.increment(coins),
      });
    });

    setState(() {
      _message = "🎉 You earned $coins coins!";
      _claimCodeController.clear();
    });
  }

  Future<void> _createPromoCode() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final String code = _createCodeController.text.trim().toUpperCase();
    final int? coins = int.tryParse(_createCoinsController.text.trim());
    final int? maxClaims = int.tryParse(_createMaxClaimsController.text.trim());

    if (code.isEmpty || coins == null || maxClaims == null || coins <= 0 || maxClaims <= 0) {
      setState(() => _message = "⚠️ Invalid input.");
      return;
    }

    final totalCost = coins * maxClaims;
    final userDocRef = _firestore.collection('users').doc(user.uid);
    final userDoc = await userDocRef.get();
    final userCoins = userDoc['coins'] ?? 0;

    if (userCoins < totalCost) {
      setState(() => _message = "⚠️ Not enough coins. You need $totalCost.");
      return;
    }

    final codeRef = _firestore.collection('promo_codes').doc(code);
    final existing = await codeRef.get();
    if (existing.exists) {
      setState(() => _message = "⚠️ Code already exists.");
      return;
    }

    await _firestore.runTransaction((transaction) async {
      transaction.set(codeRef, {
        'creator': user.uid,
        'coins': coins,
        'maxClaims': maxClaims,
        'claims': 0,
        'claimedBy': [],
        'createdAt': Timestamp.now(),
      });

      transaction.update(userDocRef, {
        'coins': FieldValue.increment(-totalCost),
      });
    });

    setState(() {
      _message = "✅ Created '$code' (Cost: $totalCost coins)";
      _createCodeController.clear();
      _createCoinsController.clear();
      _createMaxClaimsController.clear();
    });
  }

  Widget _buildSection(String title, List<Widget> children, {Color? color}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildFullWidthButton(String text, VoidCallback onPressed, Color color) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Promo Codes"),
        backgroundColor: Colors.deepPurple,
        elevation: 4,
      ),
      backgroundColor: Colors.deepPurple.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSection(
              "Claim Promo Code",
              [
                _buildTextField(_claimCodeController, "Enter Code"),
                _buildFullWidthButton("Claim", _claimPromoCode, Colors.green),
              ],
            ),
            _buildSection(
              "Create Promo Code",
              [
                _buildTextField(_createCodeController, "Promo Code"),
                _buildTextField(_createCoinsController, "Coins per Claim", type: TextInputType.number),
                _buildTextField(_createMaxClaimsController, "Max Claims", type: TextInputType.number),
                _buildFullWidthButton("Create Promo Code", _createPromoCode, Colors.white),
              ],
            ),
            const SizedBox(height: 20),
            if (_message.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  color: _message.contains("✅") || _message.contains("🎉")
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _message,
                  style: TextStyle(
                    color: _message.contains("✅") || _message.contains("🎉")
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
