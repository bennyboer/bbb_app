import 'dart:async';

import 'package:bbb_app/src/connect/meeting/main_websocket/module.dart';

import 'model/user.dart';

/// Module dealing with meeting participants/user information.
class UserModule extends Module {
  /// Stream controller to publish participant changes with.
  StreamController<UserEvent> _userStreamController =
  StreamController.broadcast();

  /// Map of users we currently have fetched from the web socket.
  Map<String, User> _userMapByInternalId = {};
  Map<String, String> _internalIdToId = {};
  Map<String, String> _idToInternalId = {};

  UserModule(messageSender) : super(messageSender);

  @override
  void onConnected() {
    subscribe("users");
  }

  @override
  Future<void> onDisconnect() {
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

      // this has to id, not internal ID (internalID is not included in all received messages relating this user)
      String internalId = _idToInternalId.putIfAbsent(
          jsonMsg['id'], () => fields['intId']);
      _internalIdToId.putIfAbsent(internalId, () => jsonMsg['id']);
      User u = _userMapByInternalId.putIfAbsent(
          internalId, () => User());

      // TODO create some nicer mapper
      if (internalId != null) u.internalId = internalId;

      if (fields['name'] != null) u.name = fields['name'];

      if (fields['sortName'] != null)
        u.sortName = fields['sortName'];

      if (fields['color'] != null)
        u.color = fields['color'];

      if (fields['role'] != null) u.role = fields['role'];

      if (fields['presenter'] != null)
        u.isPresenter = fields['presenter'];

      if (fields['connectionStatus'] != null)
        u.connectionStatus = fields['connectionStatus'];

      if (fields.containsKey("ejected")) {
        u.ejected = fields["ejected"];
      }

      if (u.internalId != null) _userMapByInternalId[u.internalId] = u;

      // Publish changed user map
      _userStreamController.add(UserEvent(type, u));
    }
  }

  void updateUserForId(String internalUserId, User model) {
    _userMapByInternalId[internalUserId] = model;
    _userStreamController.add(UserEvent(UserEventType.CHANGED, model));
  }

  /// Get changes of the current meetings users.
  Stream<UserEvent> get changes => _userStreamController.stream;

  /// Get the current user map by internal ID.
  Map<String, User> get userMapByInternalId => _userMapByInternalId;
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
