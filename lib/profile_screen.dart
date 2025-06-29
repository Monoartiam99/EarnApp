import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = '';
  String email = '';
  String phone = '';
  int coins = 0;
  bool isLoading = true;
  bool phoneAlreadySet = false;

  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            name = data['name'] ?? 'No Name';
            email = data['email'] ?? 'No Email';
            phone = data['phone'] ?? '';
            coins = data['coins'] ?? 0;
            _phoneController.text = phone;
            phoneAlreadySet = phone.isNotEmpty;
            isLoading = false;
          });
        } else {
          setState(() {
            name = 'No data found';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        name = 'Error loading data';
        isLoading = false;
      });
    }
  }

  Future<void> updatePhone() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _phoneController.text.isNotEmpty && !phoneAlreadySet) {
      final phoneText = _phoneController.text.trim();
      if (phoneText.length == 10 && RegExp(r'^\d{10}$').hasMatch(phoneText)) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'phone': phoneText});
        setState(() {
          phone = phoneText;
          phoneAlreadySet = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number updated!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter valid 10-digit phone number')),
        );
      }
    }
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = const Color(0xFF7B1FA2); // Deep Violet
    final Color lightViolet = const Color(0xFFE1BEE7);

    return Scaffold(
      backgroundColor: lightViolet.withOpacity(0.15),
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text("My Profile"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              CircleAvatar(
                radius: 55,
                backgroundColor: lightViolet,
                child: const Icon(Icons.person, size: 60, color: Colors.deepPurple),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 30),
              profileItem("Email", email, primary),
              const SizedBox(height: 16),
              profileItem("Coins", coins.toString(), primary),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                readOnly: phoneAlreadySet,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  labelText: "Phone",
                  filled: true,
                  fillColor: phoneAlreadySet ? Colors.grey[200] : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (!phoneAlreadySet)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: updatePhone,
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text("Update Phone", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                )
              else
                const Text(
                  "Phone number already set and cannot be updated again.",
                  style: TextStyle(color: Colors.grey),
                ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: logout,
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 36),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget profileItem(String title, String value, Color borderColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title:",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: borderColor.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
