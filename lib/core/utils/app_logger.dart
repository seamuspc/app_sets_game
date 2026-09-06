import 'package:logger/logger.dart';

/// A single shared logger instance. Use this instead of `print()` —
/// it's stripped from release builds more cleanly and gives you
/// log levels (debug/info/warning/error) with readable formatting.
///
/// Usage:
///   appLogger.i('User signed in');
///   appLogger.w('Cache miss, falling back to network');
///   appLogger.e('Failed to save', error: e, stackTrace: st);
final Logger appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 1,
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: true,
  ),
);
