import 'dart:async';

import 'package:bbb_app/src/connect/meeting/main_websocket/chat/chat.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/main_websocket.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/video/video_connection.dart';
import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:bbb_app/src/locale/app_localizations.dart';
import 'package:bbb_app/src/view/main/presentation/presentation_widget.dart';
import 'package:bbb_app/src/view/meeting_info/meeting_info_view.dart';
import 'package:bbb_app/src/view/settings/settings_view.dart';
import 'package:bbb_app/src/view/start/start_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// The main view including the current presentation/webcams/screenshare.
class MainView extends StatefulWidget {
  /// Info of the meeting to display.
  MeetingInfo _meetingInfo;

  MainView(this._meetingInfo);

  @override
  State<StatefulWidget> createState() => _MainViewState();
}

/// State of the main view.
class _MainViewState extends State<MainView> with WidgetsBindingObserver {
  /// Main websocket connection of the meeting.
  MainWebSocket _mainWebSocket;

  /// List of video streams we currently display.
  Map<String, VideoConnection> _videoConnections;

  /// Counter for total unread messages.
  int _totalUnreadMessages = 0;

  /// Subscription to video connection list changes.
  StreamSubscription _videoConnectionsStreamSubscription;

  /// Subscription to unread message counter updates.
  StreamSubscription<UnreadMessageCounterEvent>
      _unreadMessageCounterStreamSubscription;

  @override
  void initState() {
    super.initState();

    _mainWebSocket = MainWebSocket(widget._meetingInfo);

    _videoConnections = _mainWebSocket.videoModule.videoConnections;
    _videoConnectionsStreamSubscription =
        _mainWebSocket.videoModule.videoConnectionsStream.listen((videoConnections) {
      setState(() => _videoConnections = videoConnections);
    });

    _updateTotalUnreadMessagesCounter();
    _unreadMessageCounterStreamSubscription =
        _mainWebSocket.chatModule.unreadMessageCounterStream.listen((event) {
      setState(() => _updateTotalUnreadMessagesCounter());
    });

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _videoConnectionsStreamSubscription.cancel();
    _unreadMessageCounterStreamSubscription.cancel();

    _mainWebSocket.disconnect();

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _onAppClose();
    }
  }

  /// Called when the app is closed by the user.
  void _onAppClose() {
    if (_mainWebSocket != null) {
      _mainWebSocket.disconnect();
    }
  }

  /// Update the total unread messages counter.
  void _updateTotalUnreadMessagesCounter() {
    _totalUnreadMessages = 0;
    _mainWebSocket.chatModule.unreadMessageCounters
        .forEach((key, value) => _totalUnreadMessages += value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Text("Your username is: ${widget._meetingInfo.fullUserName}"),
          Text("Having ${_videoConnections.length} cameras active"),
          Expanded(
            child: PresentationWidget(_mainWebSocket),
          ),
          ListView.builder(
              padding: const EdgeInsets.all(8),
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemCount: _videoConnections.length,
              itemBuilder: (BuildContext context, int index) {
                String key = _videoConnections.keys.elementAt(index);
                return Container(
                    width: 200,
                    height: 200,
                    child: RTCVideoView(_videoConnections[key].remoteRenderer));
              }),
        ],
      ),
    );
  }

  /// Build the main views application bar.
  Widget _buildAppBar() => AppBar(
        title: Text(widget._meetingInfo.conferenceName),
        leading: IconButton(
          icon: Stack(
            children: [
              Icon(Icons.people),
              if (_totalUnreadMessages > 0)
                Container(
                  margin: EdgeInsets.only(top: 12, left: 15),
                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).errorColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "${_totalUnreadMessages}",
                    softWrap: false,
                    style: TextStyle(
                        color:
                            Theme.of(context).primaryTextTheme.bodyText1.color),
                  ),
                ),
            ],
          ),
          tooltip: AppLocalizations.of(context).get("meeting-info.title"),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    MeetingInfoView(widget._meetingInfo, _mainWebSocket),
              ),
            );
          },
        ),
        actions: [
          _buildPopupMenu(),
        ],
      );

  /// Build the popup menu of the app bar.
  Widget _buildPopupMenu() => PopupMenuButton(
        onSelected: (value) {
          if (value == "settings") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsView()),
            );
          } else if (value == "logout") {
            // Main websocket will be disconnected in the dispose method automatically,
            // so no need to do it here.
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => StartView()),
            );
          }
        },
        itemBuilder: (context) {
          return [
            PopupMenuItem<String>(
              value: "settings",
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(
                      Icons.settings,
                      color: Theme.of(context).textTheme.bodyText1.color,
                    ),
                  ),
                  Text(AppLocalizations.of(context).get("settings.title")),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: "logout",
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(Icons.logout,
                        color: Theme.of(context).textTheme.bodyText1.color),
                  ),
                  Text(AppLocalizations.of(context).get("main.logout")),
                ],
              ),
            ),
          ];
        },
      );
}
