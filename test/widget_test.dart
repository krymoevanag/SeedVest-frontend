import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:seedvest_mobile/viewmodels/user_viewmodel.dart';
import 'package:seedvest_mobile/views/auth/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  testWidgets('SplashScreen renders branding text', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await dotenv.load(fileName: '.env');

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserViewModel(),
        child: MaterialApp(
          home: const SplashScreen(),
          routes: {
            '/onboarding': (context) => const SizedBox(),
            '/login': (context) => const SizedBox(),
            '/dashboard': (context) => const SizedBox(),
          },
        ),
      ),
    );

    expect(find.text('Financial Governance & Growth'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}
