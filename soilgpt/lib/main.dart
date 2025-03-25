import 'package:flutter/material.dart';
import 'home_screen.dart';

void main() {
  runApp(CropRecommendationApp());
}

class CropRecommendationApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Crop Recommendation',
      theme: ThemeData(primarySwatch: Colors.green),
      home: HomeScreen(),
    );
  }
}
