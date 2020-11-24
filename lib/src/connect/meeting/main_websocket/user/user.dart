import 'dart:async';

import 'package:bbb_app/src/connect/meeting/main_websocket/module.dart';
import 'package:bbb_app/src/connect/meeting/model/user_model.dart';

/// Module dealing with meeting participants/user information.
class UserModule extends Module {
  /// Stream controller to publish participant changes with.
  StreamController<UserEvent> _userStreamController =
      StreamController.broadcast();

  /// Map of users we currently have fetched from the web socket.
  Map<String, UserModel> _userMapByInternalId = {};
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
      // this has to id, not internal ID (internalID is not included in all received messages relating this user)
      String internalId = _idToInternalId.putIfAbsent(jsonMsg['id'], () => jsonMsg['fields']['intId']);
      _internalIdToId.putIfAbsent(internalId, () => jsonMsg['id']);
      UserModel u = _userMapByInternalId.putIfAbsent(internalId, () => UserModel());

      //TODO create some nicer mapper
      if (internalId != null)
        u.internalId = internalId;

      if (jsonMsg['fields']['name'] != null)
        u.name = jsonMsg['fields']['name'];

      if (jsonMsg['fields']['sortName'] != null)
        u.sortName = jsonMsg['fields']['sortName'];

      if (jsonMsg['fields']['color'] != null)
        u.color = jsonMsg['fields']['color'];

      if (jsonMsg['fields']['role'] != null)
        u.role = jsonMsg['fields']['role'];

      if (jsonMsg['fields']['presenter'] != null)
        u.isPresenter = jsonMsg['fields']['presenter'];

      if (jsonMsg['fields']['connectionStatus'] != null)
        u.connectionStatus = jsonMsg['fields']['connectionStatus'];

      if (u.internalId != null)
        _userMapByInternalId[u.internalId] = u;

      // Publish changed user map
      _userStreamController.add(UserEvent(type, u));
    }
  }

  void updateUserForId(String internalUserId, UserModel model) {
    _userMapByInternalId[internalUserId] = model;
    _userStreamController.add(UserEvent(UserEventType.CHANGED, model));
  }

  /// Get changes of the current meetings users.
  Stream<UserEvent> get changes => _userStreamController.stream;

  /// Get the current user map by internal ID.
  Map<String, UserModel> get userMapByInternalId => _userMapByInternalId;
}

/// Event for users.
class UserEvent {
  /// Type of the event.
  final UserEventType type;

  /// Data the event relates to.
  final UserModel data;

  UserEvent(this.type, this.data);
}

/// Available user event types.
enum UserEventType { ADDED, CHANGED }
