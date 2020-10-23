/// Info needed to join a meeting.
class MeetingInfo {
  /// URL of the meeting.
  String _meetingURL;

  /// Token of the current session.
  String _sessionToken;

  MeetingInfo(this._meetingURL, this._sessionToken);

  String get sessionToken => _sessionToken;

  String get meetingURL => _meetingURL;
}
