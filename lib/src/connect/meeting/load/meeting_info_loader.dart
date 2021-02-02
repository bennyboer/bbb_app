import 'package:bbb_app/src/connect/meeting/meeting_info.dart';

/// Updater for the loading status.
typedef void WaitingRoomStatusUpdater(bool isWaitingRoom);
typedef void MeetingNotStartedStatusUpdater(bool meetingNotStarted);

/// Loader for meeting infos.
abstract class MeetingInfoLoader {
  /// Load meeting info for the passed [meetingUrl], [password] and [name].
  Future<MeetingInfo> load(
    String meetingUrl,
    String password,
    String name, {
    WaitingRoomStatusUpdater waitingRoomStatusUpdater,
    MeetingNotStartedStatusUpdater meetingNotStartedStatusUpdater,
  });

  /// Fired if connect attempt is canceled by user.
  void cancel();
}
