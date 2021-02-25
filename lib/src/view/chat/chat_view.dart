import 'dart:async';

import 'package:bbb_app/src/connect/meeting/main_websocket/chat/chat.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/chat/group.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/chat/message.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/chat/user_typing_info.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/main_websocket.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/user/model/user.dart';
import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:bbb_app/src/locale/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:sprintf/sprintf.dart';

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

  /// List of currently typing users.
  List<String> _currentlyTypingUsers = [];

  /// Subscription to incoming chat messages.
  StreamSubscription<ChatMessageEvent> _chatMessageStreamSubscription;

  /// Subscription to user is typing status updates.
  StreamSubscription<UserTypingInfo> _userTypingInfoStreamSubscription;

  /// Controller for the text field.
  final TextEditingController _textFieldController = TextEditingController();

  /// Scroll controller of the chat list.
  final ScrollController _scrollController = ScrollController();

  /// Timer started, when the current user types.
  Timer _userTypingTimer;

  @override
  void initState() {
    super.initState();

    // Reset unread message counter as the user is currently actively viewing the chat.
    widget._mainWebSocket.chatModule
        .resetUnreadMessageCounter(widget._chatGroup.id);

    _messages.addAll(
        widget._mainWebSocket.chatModule.getMessages(widget._chatGroup.id));
    _chatMessageStreamSubscription =
        widget._mainWebSocket.chatModule.messageStream.listen((event) {
      if (event.target.chatID == widget._chatGroup.id) {
        // Reset unread message counter as the user is currently actively viewing the chat.
        widget._mainWebSocket.chatModule
            .resetUnreadMessageCounter(widget._chatGroup.id);

        setState(() {
          if (event.added) {
            _messages.add(event.target);
          } else {
            _messages
                .removeWhere((msg) => msg.messageID == event.target.messageID);
          }
        });

        _scrollToEnd();
      }
    });

    _currentlyTypingUsers = List.of(widget._mainWebSocket.chatModule
        .getUserTypingInfo(widget._chatGroup.id));
    _currentlyTypingUsers.sort();
    _userTypingInfoStreamSubscription = widget
        ._mainWebSocket.chatModule.userTypingStatusStream
        .listen((userTypingInfo) {
      if (userTypingInfo.chatID == widget._chatGroup.id) {
        bool keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

        // Prevent the keyboard from closing
        if (!keyboardOpen) {
          setState(() {
            _currentlyTypingUsers = List.of(widget._mainWebSocket.chatModule
                .getUserTypingInfo(widget._chatGroup.id));
            _currentlyTypingUsers.sort();

            if (_scrollController.offset >=
                _scrollController.position.maxScrollExtent) {
              _scrollToEnd();
            }
          });
        }
      }
    });

    _textFieldController.addListener(() {
      if (_userTypingTimer != null) {
        _userTypingTimer.cancel();
      } else {
        widget._mainWebSocket.chatModule.startUserTyping(
          widget._chatGroup.id == ChatModule.defaultChatID
              ? null
              : widget._chatGroup.id,
        );
      }

      _userTypingTimer = Timer(Duration(seconds: 2), () {
        widget._mainWebSocket.chatModule.stopUserTyping();
        _userTypingTimer = null;
      });
    });

    // Restore text draft (if any saved previously)
    _textFieldController.text = widget._mainWebSocket.chatModule
            .restoreTextDraft(widget._chatGroup.id) ??
        "";

    _scrollToEnd();
  }

  /// Scroll to the end of the chat.
  void _scrollToEnd() {
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
    _userTypingInfoStreamSubscription.cancel();

    _scrollController.dispose();

    // Save current text draft
    widget._mainWebSocket.chatModule
        .saveTextDraft(widget._chatGroup.id, _textFieldController.text);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
          bottom: true,
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  itemCount: _messages.length,
                  controller: _scrollController,
                  itemBuilder: (BuildContext context, int index) {
                    ChatMessage message = _messages[index];
                    User sender = widget._mainWebSocket.userModule
                        .getUserByID(message.senderID);

                    return _buildChatMessageWidget(
                      message,
                      sender,
                      context,
                    );
                  },
                ),
              ),
              if (_currentlyTypingUsers.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(5),
                  color: null,
                  child: Text(
                    sprintf(
                        (_currentlyTypingUsers.length == 1
                            ? AppLocalizations.of(context)
                                .get("chat.currently-typing-singular")
                            : AppLocalizations.of(context)
                                .get("chat.currently-typing-plural")),
                        [_currentlyTypingUsers.join(", ")]),
                    style: TextStyle(fontStyle: FontStyle.italic),
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
                          hintText: AppLocalizations.of(context)
                              .get("chat.text-to-send"),
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
          )),
    );
  }

  /// Send a message.
  Future<void> _sendMessage(String message) async {
    if (message.isNotEmpty) {
      await widget._mainWebSocket.chatModule.sendGroupChatMsg(ChatMessage(
        "OUTGOING",
        message,
        chatID: widget._chatGroup.id,
      ));

      _scrollToEnd();
    }
  }

  /// Build widget to display a chat message.
  Widget _buildChatMessageWidget(
      ChatMessage msg, User sender, BuildContext context) {
    final bool isCurrentUser = sender.id == widget._meetingInfo.internalUserID;

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
  Widget _buildUserBubble(User user, BuildContext context) {
    final bool isCurrentUser = user.id == widget._meetingInfo.internalUserID;

    return Container(
      width: 50,
      height: 50,
      margin: EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        borderRadius: user.role == User.ROLE_MODERATOR
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
          ? AppLocalizations.of(context).get("chat.public")
          : widget._chatGroup.name),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios),
        tooltip: AppLocalizations.of(context).get("back"),
        onPressed: () {
          Navigator.pop(context);
        },
      ));
}
