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
  bool isLoading = true;
  bool canEditPhone = false;
  final TextEditingController _phoneController = TextEditingController();
  bool phoneUpdated = false;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            name = data['name'] ?? 'No Name';
            email = data['email'] ?? 'No Email';
            phone = data['phone'] ?? '';
            _phoneController.text = phone;
            // Allow edit ONLY if Google user
            canEditPhone = user.providerData.any(
              (info) => info.providerId == 'google.com',
            );
            phoneUpdated = phone.isNotEmpty;
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

  void logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AuthScreen()),
      (route) => false,
    );
  }

  void toggleEditPhone() {
    setState(() {
      canEditPhone = !canEditPhone;
      if (!canEditPhone) {
        // Save the phone number if editing is disabled
        phone = _phoneController.text;
        // Here you can add the code to update the phone number in Firestore
      }
    });
  }

  Future<void> updatePhone() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _phoneController.text.isNotEmpty) {
      // Only allow 10-digit numerical phone numbers
      if (_phoneController.text.length == 10 && RegExp(r'^\d{10}$').hasMatch(_phoneController.text)) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'phone': _phoneController.text,
        });
        setState(() {
          phone = _phoneController.text;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number updated!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid 10-digit phone number')),
        );
      }
    }
  }
          .update({
        'phone': _phoneController.text,
      });
      setState(() {
        phone = _phoneController.text;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number updated!')),
      );
    }
  }
      setState(() {
        phone = _phoneController.text;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number updated!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = const Color(0xFF7B1FA2); // Deep Violet
    final Color lightViolet = const Color(0xFFE1BEE7);

    return Scaffold(
      backgroundColor: lightViolet.withOpacity(0.15),
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        title: const Text(
          "My Profile",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              CircleAvatar(
                radius: 55,
                backgroundColor: lightViolet,
                child: const Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name.isNotEmpty ? name : 'Loading...',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 30),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                    children: [
                      profileItem("Email", email, primary),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                labelText: "Phone",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Phone number is required';
                                }
                                if (!RegExp(r'^\d+$').hasMatch(val)) {
                                  return 'Only numbers allowed';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: isLoading ? null : updatePhone,
                            child: const Text("Update"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: logout,
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 14,
                  ),
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

  Widget profileItem(
    String title,
    String value,
    Color borderColor, {
    bool canEditPhone = false,
    Color? buttonColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        width: double.infinity,
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
        padding: const EdgeInsets.all(16),
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
            if (title == "Phone" && canEditPhone) ...[
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  hintText: "Enter your 10-digit phone number",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor, width: 2),
                  ),
                  counterText: "", // hides the counter
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                maxLength: 10,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  if (_phoneController.text.length == 10) {
                    await updatePhone();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please enter a valid 10-digit phone number',
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor ?? borderColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Save"),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    value,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  // Show edit button if Google user and phone is set, and not already editing
                  if (title == "Phone" &&
                      FirebaseAuth.instance.currentUser?.providerData.any(
                            (info) => info.providerId == 'google.com',
                          ) ==
                          true)
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.deepPurple),
                      onPressed: () {
                        setState(() {
                          canEditPhone = true;
                        });
                      },
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
