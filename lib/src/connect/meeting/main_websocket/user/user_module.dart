import 'dart:async';

import 'package:bbb_app/src/connect/meeting/main_websocket/module.dart';

import 'model/user.dart';

/// Module dealing with meeting participants/user information.
class UserModule extends Module {
  /// Stream controller to publish participant changes with.
  StreamController<UserEvent> _userStreamController =
      StreamController.broadcast();

  /// Map of users we currently have fetched from the web socket
  /// mapped by their user ID.
  Map<String, User> _usersByID = {};

  /// Mapping of the user ID to the message ID.
  Map<String, String> _userIDToMsgID = {};

  /// Mapping of the message ID to the user ID.
  Map<String, String> _msgIDToUserID = {};

  /// Information for users that have been received from another place
  /// (for example VoiceUsersModule) for a user ID that has not yet
  /// been received.
  Map<String, User> _tmpUserInfo = {};

  UserModule(messageSender) : super(messageSender);

  @override
  void onConnected() {
    subscribe("users");
  }

  @override
  Future<void> onDisconnect() async {
    _userStreamController.close();
  }

  @override
  void processMessage(Map<String, dynamic> msg) {
    final String method = msg["msg"];

    if (method == "added") {
      String collectionName = msg["collection"];

      if (collectionName == "users") {
        _handleUsersMsg(msg, UserEventType.ADDED);
      }
    } else if (method == "changed") {
      String collectionName = msg["collection"];

      if (collectionName == "users") {
        _handleUsersMsg(msg, UserEventType.CHANGED);
      }
    }
  }

  void _handleUsersMsg(Map<String, dynamic> jsonMsg, UserEventType type) {
    if (jsonMsg['id'] != null) {
      Map<String, dynamic> fields = jsonMsg['fields'];

      String userID =
          _msgIDToUserID.putIfAbsent(jsonMsg['id'], () => fields['userId']);
      _userIDToMsgID.putIfAbsent(userID, () => jsonMsg['id']);

      // Fetch existing user or create new one
      User user = _usersByID.putIfAbsent(userID, () {
        if (_tmpUserInfo.containsKey(userID)) {
          // Received user info before receiving it via the users topic.
          // Now we need to use the early data for the new user object.
          return _tmpUserInfo.remove(userID);
        } else {
          return User(userID); // Just create an empty user
        }
      });

      if (fields['name'] != null) user.name = fields['name'];
      if (fields['sortName'] != null) user.sortName = fields['sortName'];
      if (fields['color'] != null) user.color = fields['color'];
      if (fields['role'] != null) user.role = fields['role'];
      if (fields['presenter'] != null) user.isPresenter = fields['presenter'];
      if (fields['connectionStatus'] != null)
        user.connectionStatus = fields['connectionStatus'];
      if (fields.containsKey("ejected")) user.ejected = fields["ejected"];
      if (user.id != null) _usersByID[user.id] = user;

      // Publish changed user map
      _userStreamController.add(UserEvent(type, user));
    }
  }

  /// Add temporary user info that has been received for a user
  /// despite not yet being received from the users topic.
  /// This data will be added later to the regular user data when the
  /// users topic will send it to us.
  void addTmpUserInfo(User user) {
    _tmpUserInfo[user.id] = user;
  }

  /// Emit an update event for the given user.
  void emitUpdateEvent(User user) {
    _userStreamController.add(UserEvent(UserEventType.CHANGED, user));
  }

  /// Get changes of the current meetings users.
  Stream<UserEvent> get changes => _userStreamController.stream;

  /// Get a list of all current users.
  List<User> get users => List.of(_usersByID.values);

  /// Get a user by its ID.
  User getUserByID(String id) => _usersByID[id];
}

/// Event for users.
class UserEvent {
  /// Type of the event.
  final UserEventType type;

  /// Data the event relates to.
  final User data;

  UserEvent(this.type, this.data);
}

/// Available user event types.
enum UserEventType { ADDED, CHANGED }
