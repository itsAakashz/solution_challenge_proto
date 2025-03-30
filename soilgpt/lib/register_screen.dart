import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool showPassword = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    final String username = usernameController.text.trim();
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackbar("Please fill in all fields", Colors.red);
      return;
    }

    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      _showSnackbar("Please enter a valid email address", Colors.red);
      return;
    }

    if (password.length < 6) {
      _showSnackbar("Password must be at least 6 characters long", Colors.red);
      return;
    }

    if (username.length < 3) {
      _showSnackbar("Username must be at least 3 characters long", Colors.red);
      return;
    }

    setState(() => isLoading = true);

    try {
      // Check if username already exists
      bool usernameExists = await _checkUsernameExists(username);
      if (usernameExists) {
        _showSnackbar("Username is already taken, choose another", Colors.red);
        setState(() => isLoading = false);
        return;
      }

      UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send email verification
      await userCredential.user!.sendEmailVerification();
      _showSnackbar("A verification email has been sent. Please verify your email.", Colors.blue);

      // Start checking for email verification
      _checkEmailVerified(userCredential.user!, username);

    } on FirebaseAuthException catch (e) {
      String errorMessage = "An error occurred. Please try again.";
      if (e.code == 'email-already-in-use') {
        errorMessage = "This email is already registered.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Invalid email format. Please use a proper email.";
      } else if (e.code == 'weak-password') {
        errorMessage = "Your password is too weak. Try a stronger one.";
      }
      _showSnackbar(errorMessage, Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<bool> _checkUsernameExists(String username) async {
    QuerySnapshot result = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .get();
    return result.docs.isNotEmpty;
  }

  void _checkEmailVerified(User user, String username) async {
    while (true) {
      await Future.delayed(Duration(seconds: 3)); // Check every 3 seconds
      await user.reload();
      if (user.emailVerified) {
        // Save user to Firestore after email verification
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'username': username,
          'email': user.email,
        });

        _showSnackbar("Email verified! Redirecting to login...", Colors.green);
        await Future.delayed(Duration(seconds: 2));

        if (mounted) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => LoginScreen()));
        }
        break; // Stop checking once verified
      }
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFb2f7b0), Color(0xFFd2f8d2)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Create Account",
                      style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800]),
                    ),
                    SizedBox(height: 20),
                    _buildTextField(usernameController, "Username", false),
                    SizedBox(height: 10),
                    _buildTextField(emailController, "Email", false),
                    SizedBox(height: 10),
                    _buildTextField(passwordController, "Password", true),
                    SizedBox(height: 20),
                    isLoading
                        ? CircularProgressIndicator(color: Colors.green[700])
                        : ElevatedButton(
                      onPressed: register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        padding: EdgeInsets.symmetric(
                            vertical: 14, horizontal: 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text("Register",
                          style: TextStyle(
                              fontSize: 18, color: Colors.white)),
                    ),
                    SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LoginScreen())),
                      child: Text("Already have an account? Login",
                          style: TextStyle(color: Colors.green[800])),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, bool isPassword) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !showPassword,
      keyboardType:
      isPassword ? TextInputType.text : TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
              showPassword ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => showPassword = !showPassword),
        )
            : null,
      ),
    );
  }
}
