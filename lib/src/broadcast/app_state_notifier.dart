import 'package:flutter/material.dart';

/// Notifier for changes to the global app state.
class AppStateNotifier extends ChangeNotifier {
  /// Whether dark mode is currently enabled.
  bool _isDarkMode = false;

  /// Enable or disable dark mode.
  set darkModeEnabled(bool isDarkMode) {
    this._isDarkMode = isDarkMode;
    notifyListeners();
  }

  /// Check whether dark mode is enabled.
  get darkModeEnabled {
    return _isDarkMode;
  }
}
