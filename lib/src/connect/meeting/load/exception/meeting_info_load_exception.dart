/// Exception thrown for meeting info load problems.
class MeetingInfoLoadException implements Exception {
  /// Message of the exception.
  String _message;

  MeetingInfoLoadException(this._message);

  @override
  String toString() {
    return "MeetingInfoLoadException: $_message";
  }
}

/// Exception thrown when a user has been declined from the moderator
/// in the waiting room.
class WaitingRoomDeclinedException extends MeetingInfoLoadException {
  WaitingRoomDeclinedException(String message) : super(message);
}
