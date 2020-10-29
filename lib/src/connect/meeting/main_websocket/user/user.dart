import 'dart:async';

import 'package:bbb_app/src/connect/meeting/main_websocket/module.dart';
import 'package:bbb_app/src/connect/meeting/model/user_model.dart';

/// Module dealing with meeting participants/user information.
class UserModule extends Module {
  /// Stream controller to publish participant changes with.
  StreamController<Map<String, UserModel>> _userStreamController =
      StreamController.broadcast();

  /// Map of users we currently have fetched from the web socket.
  Map<String, UserModel> _userMap = {};

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
        _handleUsersMsg(msg);
      }
    } else if (method == "changed") {
      String collectionName = msg["collection"];

      if (collectionName == "users") {
        _handleUsersMsg(msg);
      }
    }
  }

  void _handleUsersMsg(jsonMsg) {
    if (jsonMsg['id'] != null) {

      UserModel u = _userMap.putIfAbsent(jsonMsg['id'], () => UserModel());

      // UserModel u = _userMap.values.firstWhere((u) => u.id == jsonMsg['id'], orElse: () => UserModel());

      //TODO create some nicer mapper

      u.id = jsonMsg['id'];

      if(jsonMsg['fields']['name'] != null)
        u.name = jsonMsg['fields']['name'];

      if(jsonMsg['fields']['sortName'] != null)
        u.sortName = jsonMsg['fields']['sortName'];

      if(jsonMsg['fields']['intId'] != null)
        u.internalId = jsonMsg['fields']['intId'];

      if(jsonMsg['fields']['color'] != null)
        u.color = jsonMsg['fields']['color'];

      if(jsonMsg['fields']['role'] != null)
        u.role = jsonMsg['fields']['role'];

      if(jsonMsg['fields']['presenter'] != null)
        u.isPresenter = jsonMsg['fields']['presenter'];

      if(jsonMsg['fields']['connectionStatus'] != null)
        u.connectionStatus = jsonMsg['fields']['connectionStatus'];

      _userMap[u.id] = u; //this has to id, not internal ID (internalID is not included in all received messages relating this user)

      // Publish changed user map
      _userStreamController.add(_userMap);
    }
  }

  /// Get changes of the current meetings users.
  Stream<Map<String, UserModel>> get changes => _userStreamController.stream;

  /// Get the current user map.
  Map<String, UserModel> get userMap => _userMap;
}
