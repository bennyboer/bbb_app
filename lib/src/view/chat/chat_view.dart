import 'dart:async';

import 'package:bbb_app/src/connect/meeting/main_websocket/chat/chat.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/chat/group.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/chat/message.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/main_websocket.dart';
import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:bbb_app/src/connect/meeting/model/user_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';

/// Widget displaying the chat.
class ChatView extends StatefulWidget {
  /// Chat group to display chat messages of.
  final ChatGroup _chatGroup;

  /// Info of the current meeting.
  final MeetingInfo _meetingInfo;

  /// Main websocket connection for the meeting.
  final MainWebSocket _mainWebSocket;

  /// Create the view.
  ChatView(this._chatGroup, this._meetingInfo, this._mainWebSocket);

  @override
  State<StatefulWidget> createState() => _ChatViewState();
}

/// State of the chat view.
class _ChatViewState extends State<ChatView> {
  /// Messages of the chat.
  List<ChatMessage> _messages = [];

  /// Subscription to incoming chat messages.
  StreamSubscription<ChatMessage> _chatMessageStreamSubscription;

  /// Controller for the text field.
  final TextEditingController _textFieldController = TextEditingController();

  /// Scroll controller of the chat list.
  final ScrollController _scrollController = ScrollController();

  /// Whether initial scroll is needed.
  bool _needScroll = true;

  @override
  void initState() {
    super.initState();

    _messages.addAll(
        widget._mainWebSocket.chatModule.getMessages(widget._chatGroup.id));
    _chatMessageStreamSubscription =
        widget._mainWebSocket.chatModule.messageStream.listen((msg) {
      if (msg.chatID == widget._chatGroup.id) {
        setState(() {
          _messages.add(msg);
        });

        SchedulerBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 100,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    });

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _chatMessageStreamSubscription.cancel();

    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemCount: _messages.length,
              controller: _scrollController,
              itemBuilder: (BuildContext context, int index) {
                ChatMessage message = _messages[index];

                return _buildChatMessageWidget(
                  message,
                  widget._mainWebSocket.userModule.userMap[message.senderID],
                  context,
                );
              },
            ),
          ),
          Container(
            color: Theme.of(context).chipTheme.backgroundColor,
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    maxLines: 5,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: "Text to send",
                      border: InputBorder.none,
                      filled: false,
                      prefixIcon: Icon(Icons.message),
                    ),
                    style: TextStyle(fontSize: 16.0),
                    controller: _textFieldController,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    _sendMessage(_textFieldController.text);
                    _textFieldController.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Send a message.
  Future<void> _sendMessage(String message) async {
    await widget._mainWebSocket.chatModule.sendGroupChatMsg(ChatMessage(
      message,
      chatID: widget._chatGroup.id,
    ));

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  /// Build widget to display a chat message.
  Widget _buildChatMessageWidget(
      ChatMessage msg, UserModel sender, BuildContext context) {
    final bool isCurrentUser =
        sender.internalId == widget._meetingInfo.internalUserID;

    final Widget nameWidget =
        Text(sender.name, style: TextStyle(fontWeight: FontWeight.bold));
    final Widget timeWidget = Text(
        DateFormat.Hm(Localizations.localeOf(context).languageCode)
            .format(msg.timestamp));

    final Widget bubble = _buildUserBubble(sender, context);
    final Widget messageWidget = Expanded(
      child: Container(
        margin: isCurrentUser
            ? EdgeInsets.only(left: 60)
            : EdgeInsets.only(right: 60),
        decoration: BoxDecoration(
          color: Theme.of(context).chipTheme.disabledColor,
          borderRadius: BorderRadius.circular(5),
        ),
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        child: Column(
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                isCurrentUser ? timeWidget : nameWidget,
                isCurrentUser ? nameWidget : timeWidget,
              ],
            ),
            Text(msg.content),
          ],
        ),
      ),
    );

    return new Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          isCurrentUser ? messageWidget : bubble,
          isCurrentUser ? bubble : messageWidget,
        ],
      ),
    );
  }

  /// Build bubble for the passed [user].
  Widget _buildUserBubble(UserModel user, BuildContext context) {
    final bool isCurrentUser =
        user.internalId == widget._meetingInfo.internalUserID;

    return Container(
      width: 50,
      height: 50,
      margin: EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        borderRadius: user.isPresenter
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
  }

  /// Build the views application bar.
  Widget _buildAppBar() => AppBar(
      title: Text(widget._chatGroup.id == ChatModule.defaultChatID
          ? "Public chat"
          : widget._chatGroup.name),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios),
        tooltip: "Back",
        onPressed: () {
          Navigator.pop(context);
        },
      ));
}
