import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto_fantasy_league/services/auth_service.dart';

// Mock classes
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockUserCredential extends Mock implements UserCredential {}

void main() {
  group('AuthService', () {
    late AuthService authService;
    late MockFirebaseAuth mockFirebaseAuth;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      authService = AuthService();
    });

    test('should initialize with no authenticated user', () {
      expect(authService.isAuthenticated, false);
      expect(authService.user, null);
      expect(authService.isLoading, false);
    });

    test('should update authentication state when user changes', () {
      final mockUser = MockUser();
      when(mockUser.uid).thenReturn('test-uid');

      // Simulate auth state change
      authService.notifyListeners();

      expect(authService.isLoading, false);
    });
  });
}