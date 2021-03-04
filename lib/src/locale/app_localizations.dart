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
      "app.title",
      en: "BBB App",
      de: "BBB App",
    ));
    _addLocalization(_Localization(
      "app.notice",
      en: "Want to share feedback? Having problems? Click on the below GitHub link!",
      de: "Feedback oder Probleme? Klicken Sie auf den nachfolgenden GitHub Link!",
    ));
    _addLocalization(_Localization(
      "load-error",
      en: "Content could not be loaded",
      de: "Inhalt konnte nicht geladen werden",
    ));
    _addLocalization(_Localization(
      "start.uni-link-failed",
      en: "Opening the link with the app failed",
      de: "Die App konnte nicht korrekt mit dem Link geladen werden",
    ));
    _addLocalization(_Localization(
      "start.bbb-trademark",
      en: "This app uses BigBlueButton and is not endorsed or certified by BigBlueButton Inc. BigBlueButton and the BigBlueButton Logo are trademarks of BigBlueButton Inc.",
      de: "Diese App verwendet BigBlueButton, ist jedoch keine offizielle und zertifizierte App von BigBlueButton Inc. BigBlueButton sowie das BigBlueButton Logo sind Warenzeichen von BigBlueButton Inc.",
    ));
    _addLocalization(_Localization(
      "back",
      en: "Back",
      de: "Zurück",
    ));
    _addLocalization(_Localization(
      "cancel",
      en: "Cancel",
      de: "Abbrechen",
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
      "login.waiting-room-declined",
      en: "The moderator denied you access to the meeting",
      de: "Der Zutritt zum Meeting wurde vom Moderator abgewiesen",
    ));
    _addLocalization(_Localization(
      "login.in-waiting-room",
      en: "In waiting room",
      de: "Im Warteraum",
    ));
    _addLocalization(_Localization(
      "login.in-waiting-room-message",
      en: "Please wait until the moderator of the meeting is approving you joining the meeting.",
      de: "Bitte warten Sie bis der Moderator Sie zum Meeting zulässt.",
    ));
    _addLocalization(_Localization(
      "login.wait-for-meeting-to-start",
      en: "The meeting hasn't started yet.",
      de: "Die Konferenz hat noch nicht begonnen.",
    ));
    _addLocalization(_Localization(
      "login.wait-for-meeting-to-start-message",
      en: "You will automatically join when the meeting starts.",
      de: "Sie treten der Konferenz automatisch bei, sobald sie begonnen hat.",
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
      "main.about",
      en: "App information",
      de: "Über die App",
    ));
    _addLocalization(_Localization(
      "main.poll-title",
      en: "Poll: Select an option",
      de: "Umfrage: Auswahl",
    ));
    _addLocalization(_Localization(
      "main.meeting-ended",
      en: "The meeting has been ended by the moderator",
      de: "Das Meeting wurde vom Moderator beendet",
    ));
    _addLocalization(_Localization(
      "main.user-kicked",
      en: "You have been removed from the meeting",
      de: "Sie wurden vom Meeting entfernt",
    ));
    _addLocalization(_Localization(
      "privacy-policy.title",
      en: "Privacy policy",
      de: "Datenschutzerklärung",
    ));
    _addLocalization(_Localization(
      "main.share-without-presenter",
      en: "You can't share your screen if you are not the current presenter.",
      de: "Sie können Ihren Bildschirm nicht teilen, wenn Sie kein Präsentator sind.",
    ));
    _addLocalization(_Localization(
      "reconnect-audio.title",
      en: "Reconnect audio",
      de: "Audio neu verbinden",
    ));
    _addLocalization(_Localization(
      "audio.connected.snackbar",
      en: "Audio connected",
      de: "Audio-Verbindung hergestellt",
    ));
    _addLocalization(_Localization(
      "audio.connection-failed.retry.snackbar",
      en: "Audio connection failed. We will retry with another configuration!",
      de: "Audio-Verbindung fehlgeschlagen. Wir versuchen es erneut mit einer anderen Konfiguration!",
    ));
    _addLocalization(_Localization(
      "audio.connection-failed.snackbar",
      en: "Audio connection failed",
      de: "Audio-Verbindung fehlgeschlagen",
    ));
    _addLocalization(_Localization(
      "chat.public-chat-cleared",
      en: "Public chat history has been cleared by a moderator",
      de: "Der öffentliche Chatverlauf wurde von einem Moderator gelöscht",
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
