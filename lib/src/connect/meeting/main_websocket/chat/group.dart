/// Chat group or room.
class ChatGroup {
  /// ID of the chat group.
  final String _id;

  /// Name of the chat group.
  final String _name;

  ChatGroup(this._id, this._name);

  String get name => _name;

  String get id => _id;
}
