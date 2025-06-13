import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart'; // Redirect to MainScreen after login

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  bool isLogin = true;
  String email = '';
  String password = '';
  bool isLoading = false;
  String? errorMessage;

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
      }

      if (userCredential.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isSignUp = !isLogin;
    bool showPassword = false;
    bool showConfirmPassword = false;
    String confirmPassword = '';

    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(28),
            constraints: BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.15),
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: StatefulBuilder(
              builder:
                  (context, setModalState) => Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // App/Company Name
                        Center(
                          child: Text(
                            "Kamao Money",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        // Heading
                        Text(
                          isLogin ? "Sign In" : "Create New Account",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 8),
                        // Subheading
                        Text(
                          isLogin
                              ? "Welcome back! Please sign in to continue."
                              : "Let's get started by filling out the form below.",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 24),
                        // Email
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
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
                        SizedBox(height: 18),
                        // Password
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
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
                          SizedBox(height: 18),
                          // Confirm Password
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: Icon(Icons.lock_outline),
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
                        SizedBox(height: 22),
                        if (errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              errorMessage!,
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (isLoading)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
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
                              padding: EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.blue[700],
                              foregroundColor: Colors.white,
                              textStyle: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: Text(isLogin ? 'Sign in' : 'Sign up'),
                          ),
                        ),
                        SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                "OR",
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: Image.asset(
                              'assets/google_logo.png',
                              height: 24,
                              width: 24,
                            ),
                            label: Text(
                              "Continue with Google",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Colors.white,
                            ),
                            onPressed: () {
                              // TODO: Add Google sign-in logic here
                            },
                          ),
                        ),
                        SizedBox(height: 18),
                        Center(
                          child: GestureDetector(
                            onTap: () => setState(() => isLogin = !isLogin),
                            child: RichText(
                              text: TextSpan(
                                text:
                                    isLogin
                                        ? "Don't have an account? "
                                        : "Already have an account? ",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 15,
                                ),
                                children: [
                                  TextSpan(
                                    text:
                                        isLogin
                                            ? "Sign up here"
                                            : "Sign in here",
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
                        ),
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
