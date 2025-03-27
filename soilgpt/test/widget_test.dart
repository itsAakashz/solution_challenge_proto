import 'package:SoilGPT/login_screen.dart';
import 'package:SoilGPT/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';



void main() {
  testWidgets('LoginScreen is displayed when isLoggedIn is false', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(CropRecommendationApp(isLoggedIn: false));

    // Verify that the LoginScreen is displayed.
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
