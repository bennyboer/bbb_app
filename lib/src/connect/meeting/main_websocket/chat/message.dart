/// A chat message representation.
class ChatMessage {
  /// ID of the message.
  final String _messageID;

  /// ID of the chat.
  final String _chatID;

  /// Intern user ID of the sender.
  final String _senderID;

  /// Content of the message.
  final String _content;

  /// Timestamp of the message.
  final DateTime _timestamp;

  ChatMessage(
    this._messageID,
    this._content, {
    String senderID,
    String chatID,
    DateTime timestamp,
  })  : this._chatID = chatID,
        this._senderID = senderID,
        this._timestamp = timestamp;

  String get messageID => _messageID;

  String get content => _content;

  String get senderID => _senderID;

  String get chatID => _chatID;

  DateTime get timestamp => _timestamp;
}
