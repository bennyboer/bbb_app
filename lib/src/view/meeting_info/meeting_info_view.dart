import 'dart:async';

import 'package:bbb_app/src/connect/meeting/main_websocket/chat/chat.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/chat/group.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/main_websocket.dart';
import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:bbb_app/src/connect/meeting/model/user_model.dart';
import 'package:bbb_app/src/locale/app_localizations.dart';
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
            child:
                Text(AppLocalizations.of(context).get("meeting-info.messages")),
          ),
          ListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: _chatGroups.length,
            itemBuilder: (BuildContext context, int index) {
              ChatGroup group = _chatGroups[index];

              return new ListTile(
                title: Text(group.id == ChatModule.defaultChatID
                    ? AppLocalizations.of(context).get("chat.public")
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
            child: Text(
                AppLocalizations.of(context).get("meeting-info.participant")),
          ),
          _buildUsers(context),
        ],
      ),
    );
  }

  Widget _buildUsers(BuildContext context) {
    List<UserModel> currentUser = [];
    _userMap.values.forEach((u) {
      if (u.internalId == widget._meetingInfo.internalUserID) {
        currentUser.add(u);
      }
    });

    List<UserModel> moderators = [];
    _userMap.values.forEach((u) {
      if (u.role == UserModel.ROLE_MODERATOR &&
          u.internalId != widget._meetingInfo.internalUserID) {
        moderators.add(u);
      }
    });

    List<UserModel> nonModerators = [];
    _userMap.values.forEach((u) {
      if (u.role != UserModel.ROLE_MODERATOR &&
          u.internalId != widget._meetingInfo.internalUserID) {
        nonModerators.add(u);
      }
    });

    moderators.sort((a, b) => a.sortName.compareTo(b.sortName));
    nonModerators.sort((a, b) => a.sortName.compareTo(b.sortName));

    var allUsers = currentUser + moderators + nonModerators;

    return ListView.builder(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: allUsers.length,
        itemBuilder: (BuildContext context, int index) {
          UserModel user = allUsers[index];
          if (user.connectionStatus == UserModel.CONNECTIONSTATUS_ONLINE) {
            return _buildUserEntry(user, context);
          } else {
            return new SizedBox();
          }
        });
  }

  Widget _buildUserEntry(UserModel user, BuildContext context) {
    final bool isCurrentUser =
        user.internalId == widget._meetingInfo.internalUserID;

    final Widget bubble = Container(
      width: 50,
      height: 50,
      margin: EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        borderRadius: user.role == UserModel.ROLE_MODERATOR
            ? BorderRadius.circular(10)
            : BorderRadius.circular(99999),
        color: isCurrentUser
            ? Theme.of(context).disabledColor
            : Theme.of(context).accentColor,
      ),
      child: Center(
        child: Text(
          user.name.length > 2 ? user.name.substring(0, 2) : user.name,
          style: TextStyle(
              color: isCurrentUser
                  ? Theme.of(context).textTheme.bodyText1.color
                  : Theme.of(context).accentTextTheme.bodyText1.color),
        ),
      ),
    );

    return new Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          bubble,
          Text(user.isPresenter ? "(P) " + user.name : user.name),
        ],
      ),
    );
  }

  /// Build the views application bar.
  Widget _buildAppBar() => AppBar(
      title: Text(AppLocalizations.of(context).get("meeting-info.title")),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios),
        tooltip: AppLocalizations.of(context).get("back"),
        onPressed: () {
          Navigator.pop(context);
        },
      ));
}
