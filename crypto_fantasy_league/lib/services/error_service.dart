// ABOUTME: Global error handling service for managing and displaying errors
// ABOUTME: Provides centralized error state management and user-friendly error messages

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart';

class ErrorService extends ChangeNotifier {
  String? _currentError;
  ErrorType _errorType = ErrorType.none;

  String? get currentError => _currentError;
  ErrorType get errorType => _errorType;
  bool get hasError => _currentError != null;

  void setError(dynamic error, [ErrorType type = ErrorType.general]) {
    AppLogger.error('Error set in ErrorService', error);
    
    _errorType = type;
    _currentError = _getErrorMessage(error);
    notifyListeners();
  }

  void clearError() {
    AppLogger.debug('Clearing error in ErrorService');
    _currentError = null;
    _errorType = ErrorType.none;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return _getFirebaseAuthErrorMessage(error);
    } else if (error is FirebaseException) {
      return _getFirebaseErrorMessage(error);
    } else if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    } else {
      return error.toString();
    }
  }

  String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }

  String _getFirebaseErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You don\'t have permission to perform this action.';
      case 'unavailable':
        return 'Service is currently unavailable. Please try again later.';
      case 'deadline-exceeded':
        return 'Request timed out. Please check your connection and try again.';
      case 'resource-exhausted':
        return 'Too many requests. Please try again later.';
      default:
        return e.message ?? 'A service error occurred.';
    }
  }
}

enum ErrorType {
  none,
  general,
  authentication,
  network,
  validation,
  permission,
}