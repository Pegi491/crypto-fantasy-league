import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:crypto_fantasy_league/screens/auth/auth_wrapper.dart';
import 'package:crypto_fantasy_league/services/auth_service.dart';
import 'package:crypto_fantasy_league/services/error_service.dart';
import '../setup.dart';

void main() {
  group('AuthWrapper Widget Tests', () {
    late AuthService authService;
    late ErrorService errorService;

    setUpAll(() {
      setupFirebaseAuthMocks();
    });

    setUp(() {
      authService = AuthService();
      errorService = ErrorService();
    });

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: authService),
          ChangeNotifierProvider<ErrorService>.value(value: errorService),
        ],
        child: const MaterialApp(
          home: AuthWrapper(),
        ),
      );
    }

    testWidgets('should display app logo and title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Crypto Fantasy League'), findsOneWidget);
      expect(find.text('Turn on-chain trading into a game'), findsOneWidget);
      expect(find.byIcon(Icons.sports_esports), findsOneWidget);
    });

    testWidgets('should display email and password fields', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('should toggle between sign in and sign up modes', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Initially should show sign in
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Don\'t have an account? Sign Up'), findsOneWidget);

      // Tap to switch to sign up
      await tester.tap(find.text('Don\'t have an account? Sign Up'));
      await tester.pump();

      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Already have an account? Sign In'), findsOneWidget);
    });

    testWidgets('should validate email field', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final emailField = find.widgetWithText(TextFormField, 'Email');
      
      // Enter invalid email
      await tester.enterText(emailField, 'invalid-email');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('should validate password field', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final passwordField = find.widgetWithText(TextFormField, 'Password');
      
      // Leave password empty
      await tester.enterText(passwordField, '');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('should toggle password visibility', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find the password visibility toggle button
      final visibilityButton = find.byIcon(Icons.visibility);
      expect(visibilityButton, findsOneWidget);

      // Tap to toggle visibility
      await tester.tap(visibilityButton);
      await tester.pump();

      // Should now show visibility_off icon
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });
  });
}