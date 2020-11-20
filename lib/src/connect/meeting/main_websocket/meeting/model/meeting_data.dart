/// Data for a meeting.
class MeetingData {
  /// ID of the meeting.
  final String id;

  /// Whether the meeting ended.
  bool meetingEnded;

  /// Whether a poll is currently published.
  bool publishedPoll;

  /// Name of the meeting.
  String name;

  /// Whether the meeting is a breakout room.
  bool isBreakout;

  /// External meeting ID.
  String externalId;

  MeetingData({
    this.id,
    this.meetingEnded,
    this.publishedPoll,
    this.name,
    this.isBreakout,
    this.externalId,
  });
}
