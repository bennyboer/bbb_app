import 'dart:async';

import 'package:bbb_app/src/connect/meeting/main_websocket/chat/chat.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/main_websocket.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/meeting/meeting.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/poll/model/option.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/poll/model/poll.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/user/user.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/video/video_connection.dart';
import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:bbb_app/src/locale/app_localizations.dart';
import 'package:bbb_app/src/view/main/presentation/presentation_widget.dart';
import 'package:bbb_app/src/view/meeting_info/meeting_info_view.dart';
import 'package:bbb_app/src/view/privacy_policy/privacy_policy_view.dart';
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

  /// List of screenshare streams we currently display.
  Map<String, VideoConnection> _screenshareVideoConnections;

  /// Counter for total unread messages.
  int _totalUnreadMessages = 0;

  /// Subscription to video connection list changes.
  StreamSubscription _videoConnectionsStreamSubscription;

  /// Subscription to screenshare connection list changes.
  StreamSubscription _screenshareVideoConnectionsStreamSubscription;

  /// Subscription to unread message counter updates.
  StreamSubscription<UnreadMessageCounterEvent>
      _unreadMessageCounterStreamSubscription;

  /// Subscription to incoming poll events.
  StreamSubscription<Poll> _pollStreamSubscription;

  /// Subscriptions to meeting events.
  StreamSubscription<MeetingEvent> _meetingEventSubscription;

  /// Subscription to user events.
  StreamSubscription<UserEvent> _userEventStreamSubscription;

  @override
  void initState() {
    super.initState();

    _mainWebSocket = MainWebSocket(widget._meetingInfo);

    _videoConnections = _mainWebSocket.videoModule.videoConnections;
    _videoConnectionsStreamSubscription = _mainWebSocket
        .videoModule.videoConnectionsStream
        .listen((videoConnections) {
      setState(() => _videoConnections = videoConnections);
    });

    _screenshareVideoConnections =
        _mainWebSocket.videoModule.screenshareVideoConnections;
    _screenshareVideoConnectionsStreamSubscription = _mainWebSocket
        .videoModule.screenshareVideoConnectionsStream
        .listen((screenshareVideoConnections) {
      setState(
          () => _screenshareVideoConnections = screenshareVideoConnections);
    });

    _updateTotalUnreadMessagesCounter();
    _unreadMessageCounterStreamSubscription =
        _mainWebSocket.chatModule.unreadMessageCounterStream.listen((event) {
      setState(() => _updateTotalUnreadMessagesCounter());
    });

    _pollStreamSubscription =
        _mainWebSocket.pollModule.pollStream.listen((event) async {
      PollOption option = await _openPollDialog(event);

      _mainWebSocket.pollModule.vote(event.id, option.id);
    });

    _meetingEventSubscription =
        _mainWebSocket.meetingModule.events.listen((event) {
      if (event.data.id == widget._meetingInfo.meetingID &&
          event.data.meetingEnded) {
        _onMeetingEnd();
      }
    });

    _userEventStreamSubscription =
        _mainWebSocket.userModule.changes.listen((event) {
      if (event.data.internalId == widget._meetingInfo.internalUserID &&
          !event.data.isOnline()) {
        _onCurrentUserKicked();
      }
    });

    WidgetsBinding.instance.addObserver(this);
  }

  /// Called when the current user is removed from the meeting.
  void _onCurrentUserKicked() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
      return StartView(
        snackBarText: AppLocalizations.of(context).get("main.user-kicked"),
      );
    }));
  }

  /// Called when the meeting is ended.
  void _onMeetingEnd() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
      return StartView(
        snackBarText: AppLocalizations.of(context).get("main.meeting-ended"),
      );
    }));
  }

  @override
  void dispose() {
    _videoConnectionsStreamSubscription.cancel();
    _screenshareVideoConnectionsStreamSubscription.cancel();
    _unreadMessageCounterStreamSubscription.cancel();
    _pollStreamSubscription.cancel();
    _meetingEventSubscription.cancel();
    _userEventStreamSubscription.cancel();

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

  /// Open the poll dialog for the passed [poll].
  Future<PollOption> _openPollDialog(Poll poll) async {
    return await showDialog<PollOption>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(AppLocalizations.of(context).get("main.poll-title")),
          children: poll.options.map((e) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, e);
              },
              child: Text(e.key),
            );
          }).toList(growable: false),
        );
      },
    );
  }

  /// Update the total unread messages counter.
  void _updateTotalUnreadMessagesCounter() {
    _totalUnreadMessages = 0;
    _mainWebSocket.chatModule.unreadMessageCounters
        .forEach((key, value) => _totalUnreadMessages += value);
  }

  @override
  Widget build(BuildContext context) {
    String screenshareKey;
    if (_screenshareVideoConnections.length > 0) {
      screenshareKey = _screenshareVideoConnections.keys.elementAt(0);
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: <Widget>[
          if (_videoConnections.length > 0)
            Expanded(
              child: PageView.builder(
                  scrollDirection: Axis.horizontal,
                  controller: PageController(viewportFraction: 1.0),
                  itemCount: _videoConnections.length,
                  itemBuilder: (BuildContext context, int index) {
                    String key = _videoConnections.keys.elementAt(index);
                    return Container(
                      padding: const EdgeInsets.all(8),
                      width: MediaQuery.of(context).size.width,
                      child: RTCVideoView(_videoConnections[key].remoteRenderer,
                          objectFit: RTCVideoViewObjectFit
                              .RTCVideoViewObjectFitContain),
                    );
                  }),
            ),
          if (_screenshareVideoConnections.length == 0)
            Expanded(
                child: Container(
              padding: const EdgeInsets.all(8),
              child: PresentationWidget(_mainWebSocket),
            )),
          if (_screenshareVideoConnections.length > 0)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: RTCVideoView(
                    _screenshareVideoConnections[screenshareKey].remoteRenderer,
                    objectFit:
                        RTCVideoViewObjectFit.RTCVideoViewObjectFitContain),
              ),
            )
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
                    _totalUnreadMessages < 100
                        ? "${_totalUnreadMessages}"
                        : "∗",
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
          } else if (value == "about") {
            showAboutDialog(context: context);
          } else if (value == "privacy_policy") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PrivacyPolicyView()),
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
              value: "about",
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(
                      Icons.info,
                      color: Theme.of(context).textTheme.bodyText1.color,
                    ),
                  ),
                  Text(AppLocalizations.of(context).get("main.about")),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: "privacy_policy",
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(
                      Icons.privacy_tip,
                      color: Theme.of(context).textTheme.bodyText1.color,
                    ),
                  ),
                  Text(
                      AppLocalizations.of(context).get("privacy-policy.title")),
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
