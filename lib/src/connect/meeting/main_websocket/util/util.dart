import 'dart:math';

/// Utility methods for the MainWebSocket.
class MainWebSocketUtil {
  /// Available digits.
  static String _DIGITS = "1234567890";

  /// Available alphanumeric characters (excluding capitals).
  static String _ALPHANUMERIC = "abcdefghijklmnopqrstuvwxyz1234567890";

  /// Available alphanumeric characters (including capitals).
  static String _ALPHANUMERIC_WITH_CAPS =
      "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";

  static String _HEX = "abcdef1234567890";

  /// Random number generator to use.
  static Random _rng = Random();

  /// Get random digits with the given [length].
  static String getRandomDigits(int length) {
    return String.fromCharCodes(Iterable.generate(
      length,
      (_) => _DIGITS.codeUnitAt(_rng.nextInt(_DIGITS.length)),
    ));
  }

  /// Get a random string of alphanumeric characters with the given [length].
  static String getRandomAlphanumeric(int length) {
    return String.fromCharCodes(Iterable.generate(
      length,
      (_) => _ALPHANUMERIC.codeUnitAt(_rng.nextInt(_ALPHANUMERIC.length)),
    ));
  }

  /// Get a random string of alphanumeric characters (including capitals) with the given [length].
  static String getRandomAlphanumericWithCaps(int length) {
    return String.fromCharCodes(Iterable.generate(
      length,
      (_) => _ALPHANUMERIC_WITH_CAPS
          .codeUnitAt(_rng.nextInt(_ALPHANUMERIC_WITH_CAPS.length)),
    ));
  }

  /// Get a random string of hex characters with the given [length].
  static String getRandomHex(int length) {
    return String.fromCharCodes(Iterable.generate(
      length,
      (_) => _HEX.codeUnitAt(_rng.nextInt(_HEX.length)),
    ));
  }
}
