import 'dart:async';

import 'package:bbb_app/src/broadcast/module_bloc_provider.dart';
import 'package:bbb_app/src/broadcast/mute_bloc.dart';
import 'package:bbb_app/src/broadcast/snackbar_bloc.dart';
import 'package:bbb_app/src/broadcast/user_voice_status_bloc.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/chat/chat.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/main_websocket.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/meeting/meeting.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/poll/model/option.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/poll/model/poll.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/user/model/user.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/user/user_module.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/video/connection/incoming_screenshare_video_connection.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/video/connection/incoming_webcam_video_connection.dart';
import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:bbb_app/src/locale/app_localizations.dart';
import 'package:bbb_app/src/utils/log.dart';
import 'package:bbb_app/src/view/fullscreen/fullscreen_view.dart';
import 'package:bbb_app/src/view/main/presentation/presentation_widget.dart';
import 'package:bbb_app/src/view/meeting_info/meeting_info_view.dart';
import 'package:bbb_app/src/view/privacy_policy/privacy_policy_view.dart';
import 'package:bbb_app/src/view/settings/settings_view.dart';
import 'package:bbb_app/src/view/start/start_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// The main view including the current presentation/webcams/screenshare.
class MainView extends StatefulWidget {
  /// Info of the meeting to display.
  final MeetingInfo _meetingInfo;

  MainView(this._meetingInfo);

  @override
  State<StatefulWidget> createState() => _MainViewState();
}

/// State of the main view.
class _MainViewState extends State<MainView> with WidgetsBindingObserver {
  /// Main websocket connection of the meeting.
  MainWebSocket _mainWebSocket;

  /// List of video streams we currently display.
  Map<String, IncomingWebcamVideoConnection> _videoConnections;

  /// List of screenshare streams we currently display.
  Map<String, IncomingScreenshareVideoConnection> _screenshareVideoConnections;

  /// Counter for total unread messages.
  int _totalUnreadMessages = 0;

  /// Users currently taling.
  Set<String> _currentlyTalkingUsers = new Set<String>();

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

  /// Subscription to user changes.
  StreamSubscription _userChangesStreamSubscription;

  ModuleBlocProvider blocProvider = ModuleBlocProvider();

  @override
  void initState() {
    super.initState();

    blocProvider.snackbarCubit = SnackbarCubit(context);
    blocProvider.muteBloc = MuteBloc();
    blocProvider.userVoiceStatusBloc = UserVoiceStatusBloc();

    _mainWebSocket = MainWebSocket(widget._meetingInfo, this.blocProvider);

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
      if (event.data.id == widget._meetingInfo.internalUserID &&
          event.data.ejected) {
        _onCurrentUserKicked();
      }

      // Check whether user is currently talking
      if (event.type == UserEventType.CHANGED) {
        if (!event.data.talking &&
            _currentlyTalkingUsers.contains(event.data.name)) {
          setState(() {
            _currentlyTalkingUsers.remove(event.data.name);
          });
        } else if (event.data.talking &&
            !_currentlyTalkingUsers.contains(event.data.name)) {
          setState(() {
            _currentlyTalkingUsers.add(event.data.name);
          });
        }
      }
    });

    _userChangesStreamSubscription =
        _mainWebSocket.userModule.changes.listen((userMap) {
      setState(() {}); // Update widget
    });

    WidgetsBinding.instance.addObserver(this);
  }

  /// Called when the current user is removed from the meeting.
  void _onCurrentUserKicked() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
      return StartView(
        snackBarText: AppLocalizations.of(context).get("main.user-kicked"),
        processInitialUniLink: false,
      );
    }));
  }

  /// Called when the meeting is ended.
  void _onMeetingEnd() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
      return StartView(
        snackBarText: AppLocalizations.of(context).get("main.meeting-ended"),
        processInitialUniLink: false,
      );
    }));
  }

  @override
  void dispose() {
    Log.info("[MainView] Disposing MainView");

    blocProvider.snackbarCubit.close();
    blocProvider.muteBloc.close();
    blocProvider.userVoiceStatusBloc.close();

    _videoConnectionsStreamSubscription.cancel();
    _screenshareVideoConnectionsStreamSubscription.cancel();
    _unreadMessageCounterStreamSubscription.cancel();
    _pollStreamSubscription.cancel();
    _meetingEventSubscription.cancel();
    _userEventStreamSubscription.cancel();
    _userChangesStreamSubscription.cancel();

    WidgetsBinding.instance.removeObserver(this);

    _cleanupConnection();

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
    _cleanupConnection();
  }

  /// Clean up the server connection.
  Future<void> _cleanupConnection() async {
    if (_mainWebSocket != null) {
      await _mainWebSocket.disconnect();
      _mainWebSocket = null;
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

  void _micClick() {
    blocProvider.muteBloc.toggle();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SnackbarCubit>(
            create: (context) => blocProvider.snackbarCubit),
        BlocProvider<UserVoiceStatusBloc>(
            create: (context) => blocProvider.userVoiceStatusBloc),
        BlocProvider<MuteBloc>(create: (context) => blocProvider.muteBloc)
      ],
      child: Scaffold(
        appBar: _buildAppBar(),
        body: BlocListener<SnackbarCubit, String>(
          listener: (context, state) {
            if (state.isNotEmpty) {
              var controller = Scaffold.of(context).showSnackBar(SnackBar(
                content: Text(state),
              ));
              Future.delayed(
                  const Duration(seconds: 4), () => {controller.close()});
            }
          },
          child: OrientationBuilder(
            builder: (context, orientation) {
              if (orientation == Orientation.portrait) {
                return Column(
                  children: [
                    _buildCurrentlyTalkingUserList(),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          if (_videoConnections.length > 0)
                            SizedBox(
                              height: 160,
                              child: _buildCameraList(Axis.horizontal),
                            ),
                          if (_screenshareVideoConnections.length == 0)
                            Expanded(
                              child: _buildPresentationWidget(),
                            ),
                          if (_screenshareVideoConnections.length > 0)
                            Expanded(
                              child: _buildScreenShareWidget(),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildCurrentlyTalkingUserList(),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          if (_videoConnections.length > 0)
                            SizedBox(
                              width: 200,
                              child: _buildCameraList(Axis.vertical),
                            ),
                          if (_screenshareVideoConnections.length == 0)
                            Expanded(
                              child: _buildPresentationWidget(),
                            ),
                          if (_screenshareVideoConnections.length > 0)
                            Expanded(
                              child: _buildScreenShareWidget(),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),
        floatingActionButton: BlocBuilder<UserVoiceStatusBloc, UserVoiceStatus>(
          builder: (context, voiceState) => BlocBuilder<MuteBloc, MuteState>(
            builder: (context, muteState) => FloatingActionButton(
              child: voiceState == UserVoiceStatus.connected
                  ? Icon(
                      (muteState == MuteState.UNMUTED)
                          ? Icons.mic_outlined
                          : Icons.mic_off_outlined,
                      size: 30,
                      color: Theme.of(context).iconTheme.color,
                    )
                  : SizedBox(
                      width: 25,
                      height: 25,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            new AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
              onPressed: _micClick,
              elevation: 4.0,
              backgroundColor:
                  Theme.of(context).buttonTheme.colorScheme.primary,
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: Builder(
          builder: (context) => BottomAppBar(
            child: Container(
                margin: EdgeInsets.only(left: 12.0, right: 12.0),
                child: _buildBottomAppBarRow(context)),
            //to add a space between the FAB and BottomAppBar
            shape: CircularNotchedRectangle(),
            //color of the BottomAppBar
            color: Theme.of(context).appBarTheme.color,
          ),
        ),
      ),
    );
  }

  /// Build a list of currently talking users.
  Widget _buildCurrentlyTalkingUserList() {
    List<Widget> badges = _currentlyTalkingUsers
        .map((e) => _buildCurrentlyTalkingUserBadge(e))
        .toList(growable: false);

    return SizedBox(
      height: 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: badges,
      ),
    );
  }

  /// Build badge for a currently talking user.
  Widget _buildCurrentlyTalkingUserBadge(String userName) {
    return new Flexible(
      fit: FlexFit.loose,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9999),
          color: Theme.of(context).buttonColor,
        ),
        child: Text(
          userName,
          softWrap: false,
          overflow: TextOverflow.fade,
        ),
      ),
    );
  }

  /// Build the screen share widget.
  Widget _buildScreenShareWidget() {
    String screenshareKey = _screenshareVideoConnections.keys.first;

    RTCVideoView videoView = RTCVideoView(
      _screenshareVideoConnections[screenshareKey].remoteRenderer,
      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
    );

    return Container(
      padding: const EdgeInsets.all(8),
      child: Stack(
        children: [
          if (!_screenshareVideoConnections[screenshareKey]
              .remoteRenderer
              .renderVideo)
            Center(child: CircularProgressIndicator()),
          videoView,
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: Icon(Icons.fullscreen),
              color: Colors.grey,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullscreenView(child: videoView),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build the presentation widget to show.
  Widget _buildPresentationWidget() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: PresentationWidget(_mainWebSocket),
    );
  }

  /// Build the webcam list.
  Widget _buildCameraList(Axis axis) {
    return PageView.builder(
      scrollDirection: axis,
      controller:
          PageController(viewportFraction: axis == Axis.horizontal ? 0.6 : 0.4),
      itemCount: _videoConnections.length,
      itemBuilder: (BuildContext context, int index) {
        String key = _videoConnections.keys.elementAt(index);

        bool videoShown = _videoConnections[key].remoteRenderer.renderVideo;

        RTCVideoRenderer remoteRenderer = _videoConnections[key].remoteRenderer;

        RTCVideoView videoView = RTCVideoView(remoteRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain);

        return Container(
          margin: const EdgeInsets.all(8),
          color: Colors.black87,
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              children: [
                if (!videoShown) Center(child: CircularProgressIndicator()),
                videoView,
                Container(
                  margin: EdgeInsets.only(top: 10),
                  alignment: Alignment.topCenter,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white.withOpacity(0.7),
                    ),
                    child: Text(
                      _mainWebSocket.userModule
                          .getUserByID(_videoConnections[key].internalUserId)
                          .name,
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(Icons.fullscreen),
                    color: Colors.grey,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              FullscreenView(child: videoView),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds the Icons for the Bottom Navigation Bar
  Widget _buildBottomAppBarRow(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        IconButton(
          onPressed: () => _toggleWebcamOnOff(context),
          iconSize: 27.0,
          icon: Icon(
            _mainWebSocket.videoModule.isWebcamActive()
                ? Icons.photo_camera
                : Icons.photo_camera_outlined,
          ),
        ),
        IconButton(
          onPressed: _mainWebSocket.videoModule.isWebcamActive()
              ? () => _toggleWebcamFrontBack(context)
              : null,
          iconSize: 27.0,
          icon: Icon(
            _mainWebSocket.videoModule.isWebcamActive()
                ? Icons.flip_camera_ios
                : Icons.flip_camera_ios_outlined,
          ),
        ),
        //to leave space in between the bottom app bar items and below the FAB
        SizedBox(
          width: 50.0,
        ),
        IconButton(
          onPressed:
              _isPresenter() ? () => _toggleScreenshareOnOff(context) : null,
          iconSize: 27.0,
          icon: Icon(
            _mainWebSocket.videoModule.isScreenshareActive()
                ? Icons.screen_share
                : Icons.screen_share_outlined,
          ),
        ),
        IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SettingsView()),
          ),
          iconSize: 27.0,
          icon: Icon(
            Icons.settings,
          ),
        ),
      ],
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
                    _totalUnreadMessages < 100 ? "$_totalUnreadMessages" : "∗",
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
          switch (value) {
            case "settings":
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsView()),
              );
              break;
            case "logout":
              _mainWebSocket.disconnect();

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => StartView(
                    processInitialUniLink: false,
                  ),
                ),
              );
              break;
            case "about":
              showAboutDialog(context: context);
              break;
            case "privacy_policy":
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PrivacyPolicyView()),
              );
              break;
            case "reconnect_audio":
              _mainWebSocket.callModule.reconnectAudio();
              break;
          }
        },
        itemBuilder: (context) {
          return [
            PopupMenuItem<String>(
              value: "reconnect_audio",
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(
                      Icons.autorenew,
                      color: Theme.of(context).textTheme.bodyText1.color,
                    ),
                  ),
                  Text(AppLocalizations.of(context)
                      .get("reconnect-audio.title")),
                ],
              ),
            ),
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

  _toggleWebcamOnOff(BuildContext context) {
    _mainWebSocket.videoModule
        .toggleWebcamOnOff()
        .then((value) => setState(() {}));
  }

  _toggleWebcamFrontBack(BuildContext context) {
    if (_mainWebSocket.videoModule.isWebcamActive()) {
      _mainWebSocket.videoModule.toggleWebcamFrontBack();
    }
  }

  _toggleScreenshareOnOff(BuildContext context) {
    if (_isPresenter()) {
      _mainWebSocket.videoModule.toggleScreenshareOnOff();
    } else {
      var snackBarController = Scaffold.of(context).showSnackBar(SnackBar(
        content: Text(
            AppLocalizations.of(context).get("main.share-without-presenter")),
      ));
      Future.delayed(
          const Duration(seconds: 2), () => {snackBarController.close()});
    }
  }

  /// Check if the current user is the presenter.
  bool _isPresenter() {
    User currentUser = _mainWebSocket.userModule
        .getUserByID(widget._meetingInfo.internalUserID);

    return currentUser != null && currentUser.isPresenter;
  }
}
