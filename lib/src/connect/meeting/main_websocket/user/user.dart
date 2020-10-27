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
      print("adding new user...");

      String id = jsonMsg['id'];
      String name = jsonMsg['fields']['name'];
      String sortName = jsonMsg['fields']['sortName'];
      String internalId = jsonMsg['fields']['intId'];
      String color = jsonMsg['fields']['color'];
      String role = jsonMsg['fields']['role'];
      bool isPresenter = jsonMsg['fields']['presenter'];
      String connectionStatus = jsonMsg['fields']['connectionStatus'];

      _userMap[id] = UserModel(
        id,
        name,
        sortName,
        internalId,
        color,
        role,
        isPresenter,
        connectionStatus,
      );
      print(_userMap);

      // Publish changed user map
      _userStreamController.add(_userMap);
    }
  }

  /// Get changes of the current meetings users.
  Stream<Map<String, UserModel>> get changes => _userStreamController.stream;

  /// Get the current user map.
  Map<String, UserModel> get userMap => _userMap;
}
