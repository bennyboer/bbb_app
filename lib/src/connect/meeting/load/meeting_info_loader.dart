import 'package:bbb_app/src/connect/meeting/meeting_info.dart';

/// Loader for meeting infos.
abstract class MeetingInfoLoader {
  /// Load meeting info for the passed [meetingUrl].
  Future<MeetingInfo> load(String meetingUrl);
}
