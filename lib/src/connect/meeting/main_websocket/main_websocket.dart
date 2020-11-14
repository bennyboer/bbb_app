import 'dart:async';
import 'dart:convert';

import 'package:bbb_app/src/connect/meeting/main_websocket/chat/chat.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/meeting/meeting.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/module.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/ping/ping.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/poll/poll.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/presentation.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/user/user.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/util/util.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/video/video.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/voice/voice_module.dart';
import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:bbb_app/src/connect/meeting/voice/voice_connection.dart';
import 'package:bbb_app/src/utils/websocket.dart';
import 'package:http/http.dart' as http;

/// Main websocket connection to the BBB web server.
class MainWebSocket {
  /// Info of the meeting to create main websocket connection for.
  MeetingInfo _meetingInfo;

  /// Web socket instance to use.
  SimpleWebSocket _webSocket;

  /// Counter used to generate message IDs.
  int msgIdCounter = 1;

  /// Modules the web socket is delegating messages to.
  Map<String, Module> _modules;

  /// Create main web socket connection.
  MainWebSocket(this._meetingInfo) {
    _setupModules();

    final uri = Uri.parse(_meetingInfo.joinUrl)
        .replace(queryParameters: null)
        .replace(
            path:
                "html5client/sockjs/${MainWebSocketUtil.getRandomDigits(3)}/${MainWebSocketUtil.getRandomAlphanumeric(8)}/websocket");

    _webSocket = SimpleWebSocket(uri.toString(), cookie: _meetingInfo.cookie);
    print("connect to ${uri.toString()}");

    _webSocket.onOpen = () {
      print("onOpen mainWebsocket");
    };

    _webSocket.onMessage = (message) {
      print("received data on mainWebsocket: " + message);
      _processMessage(message);
    };

    _webSocket.onClose = (int code, String reason) async {
      print("mainWebsocket closed [$code => $reason]!");

      for (MapEntry<String, Module> moduleEntry in _modules.entries) {
        await moduleEntry.value.onDisconnect();
      }
    };

    _webSocket.connect();
  }

  /// Disconnect the web socket.
  Future<void> disconnect() async {
    await logout();
  }

  /// Logout the user from the meeting.
  Future<void> logout() async {
    _sendMessage({
      "msg": "method",
      "method": "userLeftMeeting",
      "params": [],
    });

    _webSocket.close();

    // Call logout URL
    await http.get(_meetingInfo.logoutUrl, headers: {
      "cookie": _meetingInfo.cookie,
    });
  }

  /// Set up the web socket modules.
  void _setupModules() {
    final MessageSender messageSender = (msg) => _sendMessage(msg);

    final UserModule userModule = new UserModule(messageSender);

    _modules = {
      "meeting": new MeetingModule(messageSender),
      "ping": new PingModule(messageSender),
      "video": new VideoModule(messageSender, _meetingInfo),
      "user": userModule,
      "chat": new ChatModule(
        messageSender,
        _meetingInfo,
        userModule,
      ),
      "presentation": new PresentationModule(messageSender, _meetingInfo),
      "poll": new PollModule(messageSender),
      "voice": new VoiceModule(messageSender, _meetingInfo),
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

          final String method = jsonMsg["msg"];
          if (method != null) {
            if (method == "connected") {
              _sendValidateAuthTokenMsg();

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

  /// Send the connect message to the server.
  void _sendConnectMsg() {
    _sendMessage({
      "msg": "connect",
      "version": "1",
      "support": ["1", "pre2", "pre1"],
    });
  }

  /// Send message to server to validate the auth token.
  void _sendValidateAuthTokenMsg() {
    _sendMessage({
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

  /// Send a message over the websocket.
  void _sendMessage(Map<String, dynamic> msgMap) {
    msgMap["id"] = "${msgIdCounter++}"; // Add global message ID

    final String msg = json.encode(msgMap).replaceAll("\"", "\\\"");

    _webSocket.send("[\"$msg\"]");
  }

  /// Get the chat module of the websocket.
  ChatModule get chatModule => _modules["chat"];

  /// Get the video module of the websocket.
  VideoModule get videoModule => _modules["video"];

  /// Get the user module of the websocket.
  UserModule get userModule => _modules["user"];

  /// Get the presentation module of the websocket.
  PresentationModule get presentationModule => _modules["presentation"];

  /// Get the poll module of the websocket.
  PollModule get pollModule => _modules["poll"];

  /// Get the meeting module of the websocket.
  MeetingModule get meetingModule => _modules["meeting"];
}
