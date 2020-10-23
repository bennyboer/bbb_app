import 'package:bbb_app/src/connect/meeting/load/bbb_meeting_info_loader.dart';

import 'meeting_info_loader.dart';

/// Factory for meeting info loaders.
class MeetingInfoLoaders {
  /// Singleton instance.
  static MeetingInfoLoaders _instance;

  /// Loader implementation to use.
  MeetingInfoLoader _loader;

  /// Retrieve the factory instance.
  factory MeetingInfoLoaders() {
    if (_instance == null) {
      _instance = MeetingInfoLoaders._internal(BBBMeetingInfoLoader());
    }

    return _instance;
  }

  /// Internal singleton constructor.
  MeetingInfoLoaders._internal(this._loader);

  /// Set the loader implementation to use for further calls.
  static setLoader(MeetingInfoLoader loader) {
    MeetingInfoLoaders._instance = MeetingInfoLoaders._internal(loader);
  }

  /// Get the loader to use.
  MeetingInfoLoader get loader => _loader;
}
