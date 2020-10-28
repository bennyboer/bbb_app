/// Chat group or room.
class ChatGroup {
  /// ID of the chat group.
  final String _id;

  /// Name of the chat group.
  final String _name;

  /// User IDs of the participants.
  final Set<String> _participantIDs;

  ChatGroup(this._id, this._name, this._participantIDs);

  String get name => _name;

  String get id => _id;

  Set<String> get participantIDs => _participantIDs;
}
