/// User typing info for "user is typing" status updates.
class UserTypingInfo {
  final String _id;
  final String _chatID;
  final String _userID;
  final String _userName;

  UserTypingInfo(
    this._id,
    this._chatID,
    this._userID,
    this._userName,
  );

  String get userName => _userName;

  String get userID => _userID;

  String get chatID => _chatID;

  String get id => _id;
}
