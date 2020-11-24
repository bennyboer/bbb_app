import 'package:logger/logger.dart';

/// Logging utility class.
class Log {
  /// Logger to use.
  static Logger _logger = Logger();

  /// Log an info message.
  static void info(dynamic message) {
    _logger.i(message);
  }

  /// Log a verbose message.
  static void verbose(dynamic message) {
    _logger.v(message);
  }

  /// Log a debug message.
  static void debug(dynamic message) {
    _logger.d(message);
  }

  /// Log a warning message.
  static void warning(dynamic message) {
    _logger.w(message);
  }

  /// Log an error.
  static void error(dynamic message, [dynamic error, StackTrace stackTrace]) {
    _logger.e(message, error, stackTrace);
  }
}
