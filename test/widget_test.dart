// This widget test verifies the app starts at the login screen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:catatan_invoice_bon_frontend/app/app.dart';
import 'package:catatan_invoice_bon_frontend/providers/auth_provider.dart';
import 'package:catatan_invoice_bon_frontend/providers/theme_provider.dart';

class MockFirebasePlatform extends FirebasePlatform {
  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return MockFirebaseApp(name ?? '[DEFAULT]', options);
  }

  @override
  FirebaseAppPlatform app([String name = '[DEFAULT]']) {
    return MockFirebaseApp(name, const FirebaseOptions(
      apiKey: 'test',
      appId: 'test',
      messagingSenderId: 'test',
      projectId: 'test',
    ));
  }
}

class MockFirebaseApp extends FirebaseAppPlatform {
  MockFirebaseApp(String name, FirebaseOptions? options)
      : super(
          name,
          options ?? const FirebaseOptions(
            apiKey: 'test',
            appId: 'test',
            messagingSenderId: 'test',
            projectId: 'test',
          ),
        );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    FirebasePlatform.instance = MockFirebasePlatform();
    await Firebase.initializeApp();
  });

  testWidgets('App shows login screen and login button', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const InvoiceBonApp(),
      ),
    );

    // Pump initial frame to build SplashScreen
    await tester.pump();

    // Verify we see "FinTrack" on the splash screen
    expect(find.text('FinTrack'), findsWidgets);

    // Advance time to pass the 2500ms splash delay and trigger navigation
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();

    // Now we should be on the LoginScreen
    expect(find.text('FinTrack'), findsWidgets);
    expect(find.text('Masuk Sekarang'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
