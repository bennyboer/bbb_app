import 'package:flutter/material.dart';

/// Localizations for the application.
class AppLocalizations {
  /// Map of localized values for keys to identify them.
  static Map<String, _Localization> _localizedValues = {};

  /// Whether the localizations are currently initialized.
  static bool _isInitialized = false;

  /// Locale of the localizations.
  final Locale _locale;

  AppLocalizations(this._locale);

  /// Get the app localizations for the passed [context].
  static AppLocalizations of(BuildContext context) {
    if (!_isInitialized) {
      _initLocalizations();
    }

    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  /// Initialize the localizations.
  static void _initLocalizations() {
    _addLocalization(_Localization(
      "bigbluebutton",
      en: "BigBlueButton",
      de: "BigBlueButton",
    ));
    _addLocalization(_Localization(
      "back",
      en: "Back",
      de: "Zurück",
    ));
    _addLocalization(_Localization(
      "login.username",
      en: "Username",
      de: "Benutzername",
    ));
    _addLocalization(_Localization(
      "login.username-missing",
      en: "Please specify a user name!",
      de: "Ein Benutzername ist erforderlich!",
    ));
    _addLocalization(_Localization(
      "login.accesscode",
      en: "Access code",
      de: "Zugangscode",
    ));
    _addLocalization(_Localization(
      "login.accesscode-missing",
      en: "Access code required!",
      de: "Zugangscode benötigt!",
    ));
    _addLocalization(_Localization(
      "login.url",
      en: "BBB Meeting URL",
      de: "BBB Meeting URL",
    ));
    _addLocalization(_Localization(
      "login.url-missing",
      en: "We need a URL to join a BBB Meeting",
      de: "Ohne URL kann dem Meeting nicht beigetreten werden",
    ));
    _addLocalization(_Localization(
      "login.join",
      en: "Join",
      de: "Beitreten",
    ));
    _addLocalization(_Localization(
      "login.join-trying",
      en: "Trying to join the meeting...",
      de: "Es wird versucht dem Meeting beizutreten...",
    ));
    _addLocalization(_Localization(
      "login.join-failed",
      en: "Could not join the meeting",
      de: "Dem Meeting konnte nicht beigetreten werden",
    ));
    _addLocalization(_Localization(
      "settings.title",
      en: "Settings",
      de: "Einstellungen",
    ));
    _addLocalization(_Localization(
      "meeting-info.title",
      en: "Meeting info",
      de: "Meeting Info",
    ));
    _addLocalization(_Localization(
      "meeting-info.participants",
      en: "Participants",
      de: "Teilnehmer",
    ));
    _addLocalization(_Localization(
      "meeting-info.messages",
      en: "Messages",
      de: "Nachrichten",
    ));
    _addLocalization(_Localization(
      "meeting-info.you",
      en: "You",
      de: "Sie",
    ));
    _addLocalization(_Localization(
      "chat.public",
      en: "Public chat",
      de: "Öffentlicher Chat",
    ));
    _addLocalization(_Localization(
      "chat.text-to-send",
      en: "Text to send",
      de: "Zu sendender Text",
    ));
    _addLocalization(_Localization(
      "chat.currently-typing-singular",
      en: "%s is currently typing",
      de: "%s schreibt gerade",
    ));
    _addLocalization(_Localization(
      "chat.currently-typing-plural",
      en: "%s are currently typing",
      de: "%s schreiben gerade",
    ));
    _addLocalization(_Localization(
      "meeting-info.create-private-chat",
      en: "Create private chat",
      de: "Privaten Chat erstellen",
    ));
    _addLocalization(_Localization(
      "main.logout",
      en: "Leave meeting",
      de: "Meeting verlassen",
    ));
    _addLocalization(_Localization(
      "main.poll-title",
      en: "Poll: Select an option",
      de: "Umfrage: Auswahl",
    ));

    _isInitialized = true;
  }

  /// Add a localized value.
  static void _addLocalization(_Localization l) {
    _localizedValues[l.key] = l;
  }

  /// Get a localized value for the passed [key].
  String get(String key) => _localizedValues[key].get(_locale.languageCode);
}

/// Localization (translations of a value for different languages).
class _Localization {
  /// Key of the localized value.
  final String _key;

  /// Translations for all supported languages (key is languageCode).
  final Map<String, _LocalizationEntry> _entries;

  _Localization(
    this._key, {
    String en,
    String de,
  }) : _entries = {
          "en": _LocalizationEntry(en, "en"),
          "de": _LocalizationEntry(de, "de"),
        };

  /// Get the key of the localized value.
  String get key => _key;

  /// Get a localized (translated) value for the given [languageCode].
  String get(String languageCode) => _entries[languageCode].value;
}

/// Entry of a localization.
class _LocalizationEntry {
  /// Value of the localization.
  final String _value;

  /// Language code of the value.
  final String _languageCode;

  _LocalizationEntry(this._value, this._languageCode);

  String get languageCode => _languageCode;

  String get value => _value;
}
