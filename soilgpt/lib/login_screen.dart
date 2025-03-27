import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'register_screen.dart';

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

      // Store login state in SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('email', email);

      // Navigate to HomeScreen
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
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

  Future<void> signInWithGoogle() async {
    setState(() => isLoading = true);

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => isLoading = false);
        return; // User canceled sign-in
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      // Check if user exists in Firestore, if not add them
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();
      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'email': userCredential.user!.email,
          'name': userCredential.user!.displayName,
          'profilePic': userCredential.user!.photoURL,
        });
      }

      // Store login state in SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('email', userCredential.user!.email ?? "");

      // Navigate to HomeScreen
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
    } catch (e) {
      showError("Google sign-in failed. Try again.");
    }

    setState(() => isLoading = false);
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
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("SOIL GPT", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green[700])),
              SizedBox(height: 30),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: "Email", border: OutlineInputBorder()),
              ),
              SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: !showPassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => showPassword = !showPassword),
                  ),
                ),
              ),
              SizedBox(height: 20),
              isLoading
                  ? CircularProgressIndicator()
                  : Column(
                children: [
                  ElevatedButton(
                    onPressed: login,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                    child: Text("Login", style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: signInWithGoogle,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, elevation: 2),
                    icon: Image.asset('assets/images/google_logo.png', height: 24), // Add Google logo in assets
                    label: Text("Sign in with Google", style: TextStyle(color: Colors.black, fontSize: 16)),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen())),
                child: Text("Create an account"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
