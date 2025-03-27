import 'package:SoilGPT/main.dart';
import 'package:SoilGPT/login_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(); // Ensure Firebase initializes
    SharedPreferences.setMockInitialValues({'isLoggedIn': false});
  });

  testWidgets('LoginScreen is displayed when isLoggedIn is false', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    // Wait for Firebase and SharedPreferences to initialize
    await tester.pumpAndSettle();

    // Verify that the LoginScreen is displayed
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
