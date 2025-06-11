import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_fantasy_league/utils/logger.dart';

void main() {
  group('AppLogger', () {
    setUp(() {
      AppLogger.init();
    });

    test('should initialize successfully', () {
      expect(() => AppLogger.init(), returnsNormally);
    });

    test('should log debug messages', () {
      expect(() => AppLogger.debug('Test debug message'), returnsNormally);
    });

    test('should log info messages', () {
      expect(() => AppLogger.info('Test info message'), returnsNormally);
    });

    test('should log warning messages', () {
      expect(() => AppLogger.warning('Test warning message'), returnsNormally);
    });

    test('should log error messages', () {
      expect(() => AppLogger.error('Test error message'), returnsNormally);
    });

    test('should handle errors with exception and stack trace', () {
      final error = Exception('Test exception');
      final stackTrace = StackTrace.current;
      
      expect(
        () => AppLogger.error('Test error with exception', error, stackTrace),
        returnsNormally,
      );
    });
  });
}