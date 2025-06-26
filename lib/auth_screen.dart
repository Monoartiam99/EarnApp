import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  bool isLogin = true;
  String name = '';
  String phone = '';
  String email = '';
  String password = '';
  String confirmPassword = '';
  bool isLoading = false;
  String? errorMessage;

  bool showPassword = false;
  bool showConfirmPassword = false;

  void _authenticate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      UserCredential userCredential;

      if (isLogin) {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({'name': name, 'email': email, 'phone': phone});
      }

      if (userCredential.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() {
          isLoading = false;
        });
        return; // User canceled
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Save user info to Firestore if new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'name': userCredential.user!.displayName,
              'email': userCredential.user!.email,
              'phone': userCredential.user!.phoneNumber,
              'photoUrl': userCredential.user!.photoURL,
            });
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isSignUp = !isLogin;

    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(28),
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: StatefulBuilder(
              builder:
                  (context, setModalState) => Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Kamao Money",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          isLogin ? "Sign In" : "Create New Account",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isLogin
                              ? "Welcome back! Please sign in to continue."
                              : "Let's get started by filling out the form below.",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (isSignUp)
                          Column(
                            children: [
                              TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Name',
                                  prefixIcon: const Icon(Icons.person_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.blue[50],
                                ),
                                onChanged: (val) => name = val,
                                validator:
                                    (val) =>
                                        val == null || val.isEmpty
                                            ? 'Enter your name'
                                            : null,
                              ),
                              const SizedBox(height: 18),
                              TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Phone',
                                  prefixIcon: const Icon(Icons.phone),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.blue[50],
                                ),
                                keyboardType: TextInputType.phone,
                                onChanged: (val) => phone = val,
                                validator:
                                    (val) =>
                                        val == null || val.isEmpty
                                            ? 'Enter your phone number'
                                            : null,
                              ),
                              const SizedBox(height: 18),
                            ],
                          ),

                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.blue[50],
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (val) => email = val,
                          validator:
                              (val) =>
                                  val!.isEmpty || !val.contains('@')
                                      ? 'Enter a valid email'
                                      : null,
                        ),
                        const SizedBox(height: 18),

                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.blue[50],
                            suffixIcon: IconButton(
                              icon: Icon(
                                showPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setModalState(
                                  () => showPassword = !showPassword,
                                );
                              },
                            ),
                          ),
                          obscureText: !showPassword,
                          onChanged: (val) => password = val,
                          validator:
                              (val) =>
                                  val!.length < 6
                                      ? 'Password must be at least 6 characters'
                                      : null,
                        ),

                        if (isSignUp) ...[
                          const SizedBox(height: 18),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.blue[50],
                              suffixIcon: IconButton(
                                icon: Icon(
                                  showConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setModalState(
                                    () =>
                                        showConfirmPassword =
                                            !showConfirmPassword,
                                  );
                                },
                              ),
                            ),
                            obscureText: !showConfirmPassword,
                            onChanged: (val) => confirmPassword = val,
                            validator:
                                (val) =>
                                    val != password
                                        ? 'Passwords do not match'
                                        : null,
                          ),
                        ],
                        const SizedBox(height: 22),

                        if (errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Center(child: CircularProgressIndicator()),
                          ),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                isLoading
                                    ? null
                                    : () {
                                      if (isSignUp &&
                                          confirmPassword != password) {
                                        setModalState(() {
                                          errorMessage =
                                              "Passwords do not match";
                                        });
                                        return;
                                      }
                                      _authenticate();
                                    },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.blue[700],
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(isLogin ? 'Sign in' : 'Sign up'),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // --- OR Divider ---
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.grey[400],
                                thickness: 1,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.grey[400],
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: Image.asset(
                              'assets/google_logo.png', // Place your Google logo in assets and add to pubspec.yaml
                              height: 24,
                              width: 24,
                            ),
                            label: const Text(
                              'Sign in with Google',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Colors.black12),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: isLoading ? null : _signInWithGoogle,
                          ),
                        ),
                        const SizedBox(height: 18),

                        GestureDetector(
                          onTap: () => setState(() => isLogin = !isLogin),
                          child: RichText(
                            text: TextSpan(
                              text:
                                  isLogin
                                      ? "Don't have an account? "
                                      : "Already have an account? ",
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 15,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      isLogin ? "Sign up here" : "Sign in here",
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
