import 'dart:async';

import 'package:bbb_app/src/connect/meeting/main_websocket/main_websocket.dart';
import 'package:bbb_app/src/connect/meeting/model/user_model.dart';
import 'package:flutter/material.dart';

/// Widget showing the meeting participants and chat (or a link to the chat).
class MeetingInfoView extends StatefulWidget {
  /// The meetings main websocket connection.
  MainWebSocket _mainWebSocket;

  MeetingInfoView(this._mainWebSocket);

  @override
  State<StatefulWidget> createState() => _MeetingInfoViewState();
}

/// State of the meeting info view.
class _MeetingInfoViewState extends State<MeetingInfoView> {
  /// Map of users currently in the meeting.
  Map<String, UserModel> _userMap = {};

  /// Subscription to user changes.
  StreamSubscription _userChangesStreamSubscription;

  @override
  void initState() {
    super.initState();

    _userMap = widget._mainWebSocket.userModule.userMap;
    _userChangesStreamSubscription =
        widget._mainWebSocket.userModule.changes.listen((userMap) {
      setState(() => _userMap = userMap);
    });
  }

  @override
  void dispose() {
    _userChangesStreamSubscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
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
              })
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
