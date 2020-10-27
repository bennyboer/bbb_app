import 'dart:async';

import 'package:bbb_app/src/connect/meeting/main_websocket/main_websocket.dart';
import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
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
}

/// State of the main view.
class _MainViewState extends State<MainView> {
  /// Main websocket connection of the meeting.
  MainWebSocket _mainWebSocket;

  /// List of camera Ids we currently display.
  List<String> _cameraIdList = [];

  /// Subscription to camera IDs list changes.
  StreamSubscription _cameraIdsStreamSubscription;

  @override
  void initState() {
    super.initState();

    _mainWebSocket = MainWebSocket(widget._meetingInfo);

    _cameraIdList = _mainWebSocket.videoModule.cameraIDs;
    _cameraIdsStreamSubscription =
        _mainWebSocket.videoModule.cameraIDsStream.listen((cameraIds) {
      setState(() => _cameraIdList = cameraIds);
    });
  }

  @override
  void dispose() {
    _cameraIdsStreamSubscription.cancel();

    _mainWebSocket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          RaisedButton(
              child: Text("Test"),
              onPressed: () => _mainWebSocket.disconnect()),
          Text("Your username is: ${widget._meetingInfo.fullUserName}"),
          Text("Having ${_cameraIdList.length} cameras active"),
          ListView.builder(
              padding: const EdgeInsets.all(8),
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemCount: _cameraIdList.length,
              itemBuilder: (BuildContext context, int index) {
                return Container(
                    width: 200,
                    height: 200,
                    child: WebCamWidget(
                      widget._meetingInfo,
                      _cameraIdList[index],
                    ));
              }),
        ],
      ),
    );
  }

  /// Build the main views application bar.
  Widget _buildAppBar() => AppBar(
        title: Text(widget._meetingInfo.conferenceName),
        leading: IconButton(
          icon: Icon(Icons.people),
          tooltip: "Meeting info",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => MeetingInfoView(_mainWebSocket)),
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
}
