import 'package:logger/logger.dart';

/// Logging utility class.
class Log {
  /// Whether verbose logging is enabled.
  static bool _allowVerbose = true;

  /// Whether debug logging is enabled.
  static bool _allowDebug = true;

  /// Logger to use.
  static Logger _logger = Logger();

  /// Disable or enable verbose logging.
  static void set allowVerbose(bool value) {
    _allowVerbose = value;
  }

  /// Disable or enable debug logging.
  static void set allowDebug(bool value) {
    _allowDebug = value;
  }

  /// Log an info message.
  static void info(dynamic message) {
    _logger.i(message);
  }

  /// Log a verbose message.
  static void verbose(dynamic message) {
    if (_allowVerbose) {
      _logger.v(message);
    }
  }

  /// Log a debug message.
  static void debug(dynamic message) {
    if (_allowDebug) {
      _logger.d(message);
    }
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
