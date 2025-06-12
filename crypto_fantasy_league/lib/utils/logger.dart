// ABOUTME: Application-wide logging utilities for debugging and error tracking
// ABOUTME: Provides structured logging with different severity levels

import 'dart:developer' as developer;

enum LogLevel { debug, info, warning, error }

class AppLogger {
  static bool _isInitialized = false;
  static LogLevel _currentLevel = LogLevel.debug;

  static void init({LogLevel level = LogLevel.debug}) {
    _currentLevel = level;
    _isInitialized = true;
    info('Logger initialized with level: ${level.name}');
  }

  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, error, stackTrace);
  }

  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }

  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  static void _log(
    LogLevel level,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (!_isInitialized) {
      developer.log(
        'Logger not initialized. Call AppLogger.init() first.',
        level: 900,
        name: 'AppLogger',
      );
      return;
    }

    if (level.index < _currentLevel.index) {
      return;
    }

    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] [${level.name.toUpperCase()}] $message';

    developer.log(
      logMessage,
      level: _getLoggerLevel(level),
      name: 'CryptoFantasyLeague',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static int _getLoggerLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }
}