import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Delegate needed to use applications localized values within the flutter app.
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  /// List of supported locales.
  static const List<Locale> supportedLocales = [
    const Locale.fromSubtags(languageCode: "en"),
    const Locale.fromSubtags(languageCode: "de"),
  ];

  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => supportedLocales
      .where((l) => l.languageCode == locale.languageCode)
      .isNotEmpty;

  @override
  Future<AppLocalizations> load(Locale locale) {
    return Future.value(AppLocalizations(locale));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
