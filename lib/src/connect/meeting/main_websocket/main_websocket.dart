import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:bbb_app/src/utils/websocket.dart';

typedef CameraIdListUpdater = void Function(List<String> cameraIds);

/// Main websocket connection to the BBB web server.
class MainWebSocket {
  /// Available digits.
  static String _DIGITS = "1234567890";

  /// Available alphanumeric characters (excluding capitals).
  static String _ALPHANUMERIC = "abcdefghijklmnopqrstuvwxyz1234567890";

  /// Available alphanumeric characters (including capitals).
  static String _ALPHANUMERIC_WITH_CAPS =
      "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";

  static int _PINGINTERVALSECONDS = 10;

  /// Random number generator to use.
  Random _rng = Random();

  /// Info of the meeting to create main websocket connection for.
  MeetingInfo _meetingInfo;

  /// List of camera Ids we currently have fetched from the web socket.
  List<String> _cameraIdList = [];

  /// Lookup of the camera ID by a stream ID.
  Map<String, String> cameraIdByStreamIdLookup = {};

  /// Web socket instance to use.
  SimpleWebSocket _webSocket;

  /// Counter used to generate message IDs.
  int msgIdCounter = 1;

  /// Updater for the cameraId list.
  CameraIdListUpdater _cameraIdListUpdater;

  /// Timer for regularly sending ping message on websocket.
  Timer _pingTimer;

  /// Create main web socket connection.
  MainWebSocket(
    this._meetingInfo, {
    CameraIdListUpdater cameraIdListUpdater,
  }) : _cameraIdListUpdater = cameraIdListUpdater {
    final uri = Uri.parse(_meetingInfo.joinUrl)
        .replace(queryParameters: null)
        .replace(
            path:
                "html5client/sockjs/${_getRandomDigits(3)}/${_getRandomAlphanumeric(8)}/websocket");

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
            } else if (msg == "connected") {
              _sendValidateAuthTokenMsg();
              _sendSubMsg("video-streams");
              _startPing();
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
      "id": _getRandomAlphanumericWithCaps(17),
      "name": topic,
      "params": [],
    });
  }

  /// Regularly send a ping message to keep the connection alive.
  _startPing() {
    if(_pingTimer == null) {
      _pingTimer = new Timer.periodic(new Duration(seconds: _PINGINTERVALSECONDS), (t) {
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

  /// Get random digits with the given [length].
  String _getRandomDigits(int length) {
    return String.fromCharCodes(Iterable.generate(
      length,
      (_) => _DIGITS.codeUnitAt(_rng.nextInt(_DIGITS.length)),
    ));
  }

  /// Get a random string of alphanumeric characters with the given [length].
  String _getRandomAlphanumeric(int length) {
    return String.fromCharCodes(Iterable.generate(
      length,
      (_) => _ALPHANUMERIC.codeUnitAt(_rng.nextInt(_ALPHANUMERIC.length)),
    ));
  }

  /// Get a random string of alphanumeric characters (including capitals) with the given [length].
  String _getRandomAlphanumericWithCaps(int length) {
    return String.fromCharCodes(Iterable.generate(
      length,
      (_) => _ALPHANUMERIC_WITH_CAPS
          .codeUnitAt(_rng.nextInt(_ALPHANUMERIC_WITH_CAPS.length)),
    ));
  }
}
