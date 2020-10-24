import 'dart:convert';
import 'dart:math';

import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:bbb_app/src/utils/websocket.dart';
import 'package:bbb_app/src/view/main/webcam/webcam_widget.dart';
import 'package:bbb_app/src/view/meeting_info/meeting_info_view.dart';
import 'package:bbb_app/src/view/settings/settings_view.dart';
import 'package:flutter/material.dart';

/// The main view including the current presentation/webcams/screenshare.
class MainView extends StatefulWidget {

  /// Info of the meeting to display.
  MeetingInfo _meetingInfo;

  MainView(this._meetingInfo);

  @override
  State<StatefulWidget> createState() => _MainViewState();

  MeetingInfo get meetingInfo => _meetingInfo;

  SimpleWebSocket _mainWebsocket;

  int msgIdCounter = 1;

}

/// State of the main view.
class _MainViewState extends State<MainView> {

  List<String>_cameraIdList = new List<String>();

  @override
  void initState() {
    super.initState();

    _createMainWebsocket();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Text("Your username is: ${widget.meetingInfo.fullUserName}"),
        ListView.builder(
            padding: const EdgeInsets.all(8),
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: _cameraIdList.length,
            itemBuilder: (BuildContext context, int index) {
              return Container(
                  width: 300,
                  height: 400,
                  child: WebCamWidget(
                      widget.meetingInfo,
                      _cameraIdList[index],
                    )
              );
            }
        ),
        ],
      ),
    );
  }


  /// Build the main views application bar.
  Widget _buildAppBar() => AppBar(
        title: Text(widget.meetingInfo.conferenceName),
        leading: IconButton(
          icon: Icon(Icons.people),
          tooltip: "Meeting info",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MeetingInfoView()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            tooltip: "Settings",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsView()),
              );
            },
          ),
        ],
      );

  _createMainWebsocket() {

    final uri = Uri.parse(widget.meetingInfo.joinUrl).replace(queryParameters: null).replace(path: "html5client/sockjs/" + _getRandomDigits(3) + "/" + _getRandomAlphanumeric(8) + "/websocket");
    print(uri);

    widget._mainWebsocket = SimpleWebSocket(uri.toString());

    print('connect to ${uri.toString()}');

    widget._mainWebsocket.onOpen = () {
      print('onOpen mainWebsocket');
    };

    widget._mainWebsocket.onMessage = (message) {
      print('received data on mainWebsocket: ' + message);
      _onMessageMainWebsocket(message);
    };

    widget._mainWebsocket.onClose = (int code, String reason) {
      print('mainWebsocket closed by server [$code => $reason]!');
    };

    widget._mainWebsocket.connect();
  }

  String _getRandomDigits(int length) {
    var chars = '1234567890';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  String _getRandomAlphanumeric(int length) {
    var chars = 'abcdefghijklmnopqrstuvwxyz1234567890';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  String _getRandomAlphanumericWithCaps(int length) {
    var chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  void _onMessageMainWebsocket(String message) async {

    if(message == "o") {
      _sendConnectMsg();
    } else {

      try {

        if(message.startsWith("a")) {
          message = message.substring(1, message.length);
        }

        List<dynamic> jsonMsgs = json.decode(message);

        jsonMsgs.forEach((jsonMsg) {

          jsonMsg = json.decode(jsonMsg);

          if (jsonMsg['msg'] != null) {

            if (jsonMsg['msg'] == "added") {

              if (jsonMsg['collection'] != null) {
                switch (jsonMsg['collection']) {

                  case 'video-streams':
                    {
                      if (jsonMsg['fields']['stream'] != null) {
                        print("adding new video stream...");
                        setState(() { _cameraIdList.add(jsonMsg['fields']['stream']); });
                        print(_cameraIdList);
                      }
                    }
                    break;

                  default:
                    break;

                }
              }
            } else if (jsonMsg['msg'] == "connected") {
              _sendValidateAuthTokenMsg();
              _sendSubMsg("video-streams");
            }
          }

        });

      } on FormatException catch (e) {
        print('invalid JSON received on mainWebsocket: ' + message);
      }
    }
  }

  void _sendConnectMsg() {
    String msg = "{\"msg\":\"connect\",\"version\":\"1\",\"support\":[\"1\",\"pre2\",\"pre1\"]}"; //TODO what are this params?
    JsonEncoder encoder = new JsonEncoder();
    widget._mainWebsocket.send("[" + encoder.convert(msg) + "]");
  }

  void _sendValidateAuthTokenMsg() {
    print(widget.meetingInfo.meetingID);
    print(widget.meetingInfo.internalUserID);
    print(widget.meetingInfo.authToken);
    print(widget.meetingInfo.externUserID);

    String msg = "{\"msg\":\"method\",\"method\":\"validateAuthToken\",\"params\":[\"" + widget.meetingInfo.meetingID + "\",\"" + widget.meetingInfo.internalUserID + "\",\"" + widget.meetingInfo.authToken + "\",\"" + widget.meetingInfo.externUserID + "\"],\"id\":\"" + widget.msgIdCounter.toString() + "\"}";
    widget.msgIdCounter++;
    JsonEncoder encoder = new JsonEncoder();
    widget._mainWebsocket.send("[" + encoder.convert(msg) + "]");
  }

  _sendSubMsg(String topic) {
    //TODO save subs in map
    String random = _getRandomAlphanumericWithCaps(17);
    String msg = "{\"msg\":\"sub\",\"id\":\"" + random + "\",\"name\":\"" + topic + "\",\"params\":[]}";
    JsonEncoder encoder = new JsonEncoder();
    widget._mainWebsocket.send("[" + encoder.convert(msg) + "]");
  }


  //TODO ping with id

}
