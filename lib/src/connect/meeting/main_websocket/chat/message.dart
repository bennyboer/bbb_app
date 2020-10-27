/// A chat message representation.
class ChatMessage {
  /// ID of the chat.
  String _chatID;

  /// Intern user ID of the sender.
  String _senderID;

  /// Content of the message.
  String _content;

  /// Timestamp of the message.
  DateTime _timestamp;

  ChatMessage({
    String chatID,
    String senderID,
    String content,
    DateTime timestamp,
  })  : this._chatID = chatID,
        this._senderID = senderID,
        this._content = content,
        this._timestamp = timestamp;

  String get content => _content;

  String get senderID => _senderID;

  String get chatID => _chatID;

  DateTime get timestamp => _timestamp;
}
