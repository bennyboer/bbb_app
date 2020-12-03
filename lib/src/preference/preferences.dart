import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// Service managing app preferences.
class Preferences {
  /// Key of the dark mode enabled preference in the shared preferences.
  static const String _darkModeKey = "dark-mode";

  /// Singleton instance.
  static Preferences _instance;

  /// Shared preferences to use for saving preferences.
  SharedPreferences _sharedPreferences;

  /// Whether dark mode is enabled.
  bool _isDarkMode = true;

  /// Stream controller emitting dark mode change events.
  StreamController<bool> _darkModeStreamController =
      StreamController.broadcast();

  /// Retrieve the factory instance.
  factory Preferences() {
    if (_instance == null) {
      _instance = Preferences._internal();
    }

    return _instance;
  }

  /// Internal singleton constructor.
  Preferences._internal() {
    _getSharedPreferences().then((sp) {
      if (sp.containsKey(_darkModeKey)) {
        isDarkMode = sp.getBool(_darkModeKey);
      }
    });
  }

  /// Get the shared preferences.
  Future<SharedPreferences> _getSharedPreferences() async {
    if (_sharedPreferences == null) {
      _sharedPreferences = await SharedPreferences.getInstance();
    }

    return _sharedPreferences;
  }

  /// Check whether dark mode is enabled.
  bool get isDarkMode => _isDarkMode;

  /// Enable or disable dark mode.
  set isDarkMode(bool value) {
    if (value != _isDarkMode) {
      _isDarkMode = value;
      _darkModeStreamController.add(value);

      _getSharedPreferences().then((sp) => sp.setBool(_darkModeKey, value));
    }
  }

  /// Get dark mode enabled changes.
  Stream<bool> get darkModeEnabledChanges => _darkModeStreamController.stream;
}
