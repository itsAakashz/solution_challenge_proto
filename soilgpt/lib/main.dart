import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(CropRecommendationApp(isLoggedIn: isLoggedIn));
}

class CropRecommendationApp extends StatelessWidget {
  final bool isLoggedIn;

  CropRecommendationApp({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Crop Recommendation',
      theme: ThemeData(primarySwatch: Colors.green),
      home: isLoggedIn ? HomeScreen() : LoginScreen(),
    );
  }
}
