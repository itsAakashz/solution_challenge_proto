import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'firebase_options.dart'; // Import the generated Firebase options

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("🔥 Firebase Initialized Successfully!");
  } catch (e) {
    print("❌ Firebase Initialization Error: $e");
  }

  // Determine the initial login status
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(CropRecommendationApp(isLoggedIn: isLoggedIn));
}

class CropRecommendationApp extends StatelessWidget {
  final bool isLoggedIn;

  const CropRecommendationApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SoilGPT',
      theme: ThemeData(primarySwatch: Colors.green),
      home: isLoggedIn ?  HomeScreen() :  LoginScreen(),
    );
  }
}
