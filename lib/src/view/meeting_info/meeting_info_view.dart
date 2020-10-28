import 'dart:async';

import 'package:bbb_app/src/connect/meeting/main_websocket/chat/chat.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/chat/group.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/main_websocket.dart';
import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:bbb_app/src/connect/meeting/model/user_model.dart';
import 'package:bbb_app/src/view/chat/chat_view.dart';
import 'package:flutter/material.dart';

/// Widget showing the meeting participants and chat (or a link to the chat).
class MeetingInfoView extends StatefulWidget {
  MeetingInfo _meetingInfo;

  /// The meetings main websocket connection.
  MainWebSocket _mainWebSocket;

  MeetingInfoView(this._meetingInfo, this._mainWebSocket);

  @override
  State<StatefulWidget> createState() => _MeetingInfoViewState();
}

/// State of the meeting info view.
class _MeetingInfoViewState extends State<MeetingInfoView> {
  /// Map of users currently in the meeting.
  Map<String, UserModel> _userMap = {};

  /// Available chat groups.
  List<ChatGroup> _chatGroups = [];

  /// Subscription to user changes.
  StreamSubscription _userChangesStreamSubscription;

  /// Subscription to chat group changes.
  StreamSubscription _chatGroupsStreamSubscription;

  @override
  void initState() {
    super.initState();

    _userMap = widget._mainWebSocket.userModule.userMap;
    _userChangesStreamSubscription =
        widget._mainWebSocket.userModule.changes.listen((userMap) {
      setState(() => _userMap = userMap);
    });

    _chatGroups.addAll(widget._mainWebSocket.chatModule.chatGroups);
    _chatGroupsStreamSubscription =
        widget._mainWebSocket.chatModule.chatGroupStream.listen((chatGroup) {
      setState(() => _chatGroups.add(chatGroup));
    });
  }

  @override
  void dispose() {
    _userChangesStreamSubscription.cancel();
    _chatGroupsStreamSubscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: Text("Nachrichten"),
          ),
          ListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: _chatGroups.length,
            itemBuilder: (BuildContext context, int index) {
              ChatGroup group = _chatGroups[index];

              return new ListTile(
                title: Text(group.id == ChatModule.defaultChatID
                    ? "Public chat"
                    : group.name),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ChatView(
                              group,
                              widget._meetingInfo,
                              widget._mainWebSocket,
                            )),
                  );
                },
              );
            },
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Text("Teilnehmer"),
          ),
          ListView.builder(
            padding: const EdgeInsets.all(8),
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: _userMap.length,
            itemBuilder: (BuildContext context, int index) {
              String key = _userMap.keys.elementAt(index);
              UserModel user = _userMap[key];
              if (user.connectionStatus == "online") {
                return new Text(user.name);
              } else {
                return new SizedBox();
              }
            },
          )
        ],
      ),
    );
  }

  /// Build the views application bar.
  Widget _buildAppBar() => AppBar(
      title: Text("Meeting Info"),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios),
        tooltip: "Back",
        onPressed: () {
          Navigator.pop(context);
        },
      ));
}
