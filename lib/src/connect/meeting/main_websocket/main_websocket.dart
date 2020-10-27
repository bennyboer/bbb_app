import 'dart:async';
import 'dart:convert';

import 'package:bbb_app/src/connect/meeting/main_websocket/chat/chat.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/module.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/util/util.dart';
import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:bbb_app/src/connect/meeting/model/user_model.dart';
import 'package:bbb_app/src/utils/websocket.dart';

typedef CameraIdListUpdater = void Function(List<String> cameraIds);
typedef UserMapUpdater = void Function(Map<String, UserModel> users);

/// Main websocket connection to the BBB web server.
class MainWebSocket {
  static int _PINGINTERVALSECONDS = 10;

  /// Info of the meeting to create main websocket connection for.
  MeetingInfo _meetingInfo;

  /// List of camera Ids we currently have fetched from the web socket.
  List<String> _cameraIdList = [];

  /// List of users we currently have fetched from the web socket.
  Map<String, UserModel> _userMap = {};

  /// Lookup of the camera ID by a stream ID.
  Map<String, String> cameraIdByStreamIdLookup = {};

  /// Web socket instance to use.
  SimpleWebSocket _webSocket;

  /// Counter used to generate message IDs.
  int msgIdCounter = 1;

  /// Updater for the cameraId list.
  CameraIdListUpdater _cameraIdListUpdater;

  /// Updater for the user list.
  UserMapUpdater _userMapUpdater;

  /// Timer for regularly sending ping message on websocket.
  Timer _pingTimer;

  /// Modules the web socket is delegating messages to.
  Map<String, Module> _modules;

  /// Create main web socket connection.
  MainWebSocket(
    this._meetingInfo, {
    CameraIdListUpdater cameraIdListUpdater,
    UserMapUpdater userMapUpdater,
  })  : _cameraIdListUpdater = cameraIdListUpdater,
        _userMapUpdater = userMapUpdater {
    _setupModules();

    final uri = Uri.parse(_meetingInfo.joinUrl)
        .replace(queryParameters: null)
        .replace(
            path:
                "html5client/sockjs/${MainWebSocketUtil.getRandomDigits(3)}/${MainWebSocketUtil.getRandomAlphanumeric(8)}/websocket");

    _webSocket = SimpleWebSocket(uri.toString());
    print("connect to ${uri.toString()}");

    _webSocket.onOpen = () {
      print("onOpen mainWebsocket");
    };

    _webSocket.onMessage = (message) {
      print("received data on mainWebsocket: " + message);
      _processMessage(message);
    };

    _webSocket.onClose = (int code, String reason) {
      print("mainWebsocket closed by server [$code => $reason]!");
      _pingTimer.cancel();
    };

    _webSocket.connect();
  }

  /// Set up the web socket modules.
  void _setupModules() {
    final MessageSender messageSender = (msg) => _sendJSONEncodedMessage(msg);

    _modules = {
      "chat": new ChatModule(messageSender),
    };
  }

  /// Process incoming [message].
  void _processMessage(String message) async {
    if (message == "o") {
      _sendConnectMsg();
    } else {
      try {
        if (message.startsWith("a")) {
          message = message.substring(1, message.length);
        }

        List<dynamic> jsonMsgs = json.decode(message);

        jsonMsgs.forEach((jsonMsg) {
          jsonMsg = json.decode(jsonMsg);

          if (jsonMsg['msg'] != null) {
            final msg = jsonMsg['msg'];

            if (msg == "added") {
              if (jsonMsg['collection'] != null) {
                switch (jsonMsg['collection']) {
                  case 'video-streams':
                    {
                      if (jsonMsg['fields']['stream'] != null) {
                        print("adding new video stream...");

                        String cameraId = jsonMsg['fields']['stream'];
                        _cameraIdList.add(cameraId);
                        print(_cameraIdList);

                        cameraIdByStreamIdLookup[jsonMsg["id"]] = cameraId;

                        // Publish changed camera ID list to the caller
                        if (_cameraIdListUpdater != null) {
                          _cameraIdListUpdater(_cameraIdList);
                        }
                      }
                    }
                    break;

                  case 'users':
                    {
                      _handleUsersMsg(jsonMsg);
                    }
                    break;

                  default:
                    break;
                }
              }
            } else if (msg == "changed") {
              if (jsonMsg['collection'] != null) {
                switch (jsonMsg['collection']) {
                  case 'users':
                    {
                      _handleUsersMsg(jsonMsg);
                    }
                    break;

                  default:
                    break;
                }
              }
            } else if (msg == "removed") {
              switch (jsonMsg['collection']) {
                case 'video-streams':
                  {
                    String streamId = jsonMsg["id"];
                    String cameraId = cameraIdByStreamIdLookup[streamId];

                    _cameraIdList.remove(cameraId);
                    print(_cameraIdList);

                    // Publish changed camera ID list to the caller
                    if (_cameraIdListUpdater != null) {
                      _cameraIdListUpdater(_cameraIdList);
                    }
                  }
                  break;

                default:
                  break;
              }
            }

            if (msg == "connected") {
              _sendValidateAuthTokenMsg();
              _sendSubMsg("video-streams");
              _sendSubMsg("users");
              _startPing();

              // Delegate incoming message to the modules.
              for (MapEntry<String, Module> moduleEntry in _modules.entries) {
                moduleEntry.value.onConnected();
              }
            } else {
              // Delegate incoming message to the modules.
              for (MapEntry<String, Module> moduleEntry in _modules.entries) {
                moduleEntry.value.processMessage(jsonMsg);
              }
            }
          }
        });
      } on FormatException catch (e) {
        print("invalid JSON received on mainWebsocket: $message");
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

      _userMap[id] = UserModel(id, name, sortName, internalId, color, role,
          isPresenter, connectionStatus);
      print(_userMap);

      // Publish changed user list to the caller
      if (_userMapUpdater != null) {
        _userMapUpdater(_userMap);
      }
    }
  }

  /// Send the connect message to the server.
  void _sendConnectMsg() {
    _sendJSONEncodedMessage({
      "msg": "connect",
      "version": "1",
      "support": ["1", "pre2", "pre1"],
    });
  }

  /// Send message to server to validate the auth token.
  void _sendValidateAuthTokenMsg() {
    _sendJSONEncodedMessage({
      "msg": "method",
      "method": "validateAuthToken",
      "params": [
        _meetingInfo.meetingID,
        _meetingInfo.internalUserID,
        _meetingInfo.authToken,
        _meetingInfo.externUserID,
      ],
      "id": "${msgIdCounter++}",
    });
  }

  /// Send subscription message to subscribe to the given [topic].
  _sendSubMsg(String topic) {
    // TODO save subs in map

    _sendJSONEncodedMessage({
      "msg": "sub",
      "id": MainWebSocketUtil.getRandomAlphanumericWithCaps(17),
      "name": topic,
      "params": [],
    });
  }

  /// Regularly send a ping message to keep the connection alive.
  _startPing() {
    if (_pingTimer == null) {
      _pingTimer =
          new Timer.periodic(new Duration(seconds: _PINGINTERVALSECONDS), (t) {
        _sendJSONEncodedMessage({
          "msg": "method",
          "method": "ping",
          "params": [],
          "id": "${msgIdCounter++}",
        });
      });
    }
  }

  /// Send a message over the websocket.
  void _sendJSONEncodedMessage(Map<String, dynamic> msgMap) {
    final String msg = json.encode(msgMap).replaceAll("\"", "\\\"");

    _webSocket.send("[\"$msg\"]");
  }

  /// Get the chat module of the websocket.
  ChatModule get chatModule => _modules["chat"];
}
