// ABOUTME: Authentication service managing user login state and Firebase Auth integration
// ABOUTME: Provides authentication methods and state management for the app

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) {
    AppLogger.info('Auth state changed: ${user?.uid ?? 'null'}');
    _user = user;
    notifyListeners();
  }

  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      _setLoading(true);
      AppLogger.info('Attempting email/password sign in');
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      AppLogger.info('Sign in successful: ${credential.user?.uid}');
      return credential;
    } catch (e, stackTrace) {
      AppLogger.error('Sign in failed', e, stackTrace);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      _setLoading(true);
      AppLogger.info('Attempting user creation');
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      AppLogger.info('User created successfully: ${credential.user?.uid}');
      return credential;
    } catch (e, stackTrace) {
      AppLogger.error('User creation failed', e, stackTrace);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      AppLogger.info('Signing out user');
      await _auth.signOut();
      AppLogger.info('Sign out successful');
    } catch (e, stackTrace) {
      AppLogger.error('Sign out failed', e, stackTrace);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      AppLogger.info('Sending password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email);
      AppLogger.info('Password reset email sent successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Password reset failed', e, stackTrace);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}