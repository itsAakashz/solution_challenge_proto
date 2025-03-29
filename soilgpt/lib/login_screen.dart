import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'package:animate_do/animate_do.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool showPassword = false;

  Future<void> login() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showError("Please enter both email and password.");
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('email', email);

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => HomeScreen()));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        showError("No user found with this email.");
      } else if (e.code == 'wrong-password') {
        showError("Incorrect password. Try again.");
      } else {
        showError(e.message ?? "Login failed.");
      }
    }

    setState(() => isLoading = false);
  }

  Future<void> resetPassword() async {
    String email = emailController.text.trim();

    if (email.isEmpty) {
      showError("Please enter your email to reset password.");
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password reset email sent!"), backgroundColor: Colors.green),
      );
    } catch (e) {
      showError("Error: ${e.toString()}");
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: FadeIn(
        duration: Duration(milliseconds: 600),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("SOIL GPT", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.green[800])),
                SizedBox(height: 30),
                _buildTextField(emailController, "Email", Icons.email, false),
                SizedBox(height: 10),
                _buildTextField(passwordController, "Password", Icons.lock, true),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: resetPassword,
                    child: Text("Forgot Password?", style: TextStyle(color: Colors.green[800], fontSize: 16)),
                  ),
                ),
                SizedBox(height: 20),
                isLoading
                    ? CircularProgressIndicator()
                    : Column(
                  children: [
                    _buildButton("Login", Colors.green[700]!, Colors.white, login),
                    SizedBox(height: 10),
                    _buildGoogleButton(),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen())),
                  child: Text("Create an account", style: TextStyle(color: Colors.green[800], fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool isPassword) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !showPassword,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon, color: Colors.green[700]),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off, color: Colors.green[700]),
          onPressed: () => setState(() => showPassword = !showPassword),
        )
            : null,
      ),
    );
  }

  Widget _buildButton(String text, Color color, Color textColor, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 100),
      ),
      child: Text(text, style: TextStyle(fontSize: 18, color: textColor)),
    );
  }

  Widget _buildGoogleButton() {
    return ElevatedButton.icon(
      onPressed: () {}, // Add Google Sign-In function
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        elevation: 2,
      ),
      icon: Image.asset('assets/images/google_logo.png', height: 24, errorBuilder: (context, error, stackTrace) => Icon(Icons.error)),
      label: Text("Sign in with Google", style: TextStyle(color: Colors.black, fontSize: 16)),
    );
  }
}