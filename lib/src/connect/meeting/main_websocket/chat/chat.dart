import 'dart:async';

import 'package:bbb_app/src/connect/meeting/main_websocket/chat/group.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/chat/message.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/chat/user_typing_info.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/module.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/util/util.dart';
import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:bbb_app/src/connect/meeting/model/user_model.dart';

/// BBB Chat representation.
class ChatModule extends Module {
  /// The default chat ID of the main public group chat.
  static const String defaultChatID = "MAIN-PUBLIC-GROUP-CHAT";

  /// Topic of chat messages to subscribe to.
  static const String _groupChatMessageTopic = "group-chat-msg";

  /// Topic where new group chats are published over.
  static const String _groupChatTopic = "group-chat";

  /// Topic where "user is typing" status updates are published.
  static const String _usersTypingTopic = "users-typing";

  /// Info for the current meeting.
  final MeetingInfo _meetingInfo;

  /// Message counter.
  int _messageCounter = 1;

  /// Controller publishing chat messages.
  StreamController<ChatMessage> _chatMessageController =
      StreamController.broadcast();

  /// Controller publishing chat groups.
  StreamController<ChatGroup> _chatGroupController =
      StreamController.broadcast();

  /// Controller publishing currently typing user status updates.
  StreamController<UserTypingInfo> _userTypingStatusController =
      StreamController.broadcast();

  /// Messages already received.
  Map<String, List<ChatMessage>> _messages = {};

  /// Already received chat groups.
  List<ChatGroup> _chatGroups = [];

  /// Message confirmation completer.
  Map<String, Completer<void>> _msgConfirmCompleters = {};

  /// Users currently typing (mapped per chat ID).
  Map<String, Set<String>> _usersTypingMap = {};

  /// Users currently typing info (mapped per typing message ID).
  /// Used to remove typing user status easily again.
  Map<String, UserTypingInfo> _usersTypingInfoMap = {};

  ChatModule(
    MessageSender messageSender,
    this._meetingInfo,
  ) : super(messageSender);

  /// Send a chat message.
  Future<void> sendGroupChatMsg(ChatMessage msg) async {
    final String senderID = msg.senderID ?? _meetingInfo.internalUserID;

    final String msgId = "$senderID-${_messageCounter++}";

    sendMessage({
      "msg": "method",
      "method": "sendGroupChatMsg",
      "params": [
        msg.chatID ?? defaultChatID,
        {
          "color": 0,
          "correlationId": msgId,
          "sender": {
            "id": senderID,
            "name": _meetingInfo.fullUserName,
          },
          "message": msg.content,
        },
      ],
    });

    return waitForSentMsgConfirmation(msgId);
  }

  /// Start that the current user is typing for the passed chatID.
  void startUserTyping([String chatID]) {
    sendMessage({
      "msg": "method",
      "method": "startUserTyping",
      "params": [
        chatID == null
            ? "public"
            : _chatGroups
                .firstWhere((element) => element.id == chatID)
                .participantIDs
                .firstWhere(
                    (element) => element != _meetingInfo.internalUserID),
      ],
    });
  }

  /// Stop that the current user is typing.
  void stopUserTyping() {
    sendMessage({
      "msg": "method",
      "method": "stopUserTyping",
      "params": [],
    });
  }

  /// Create a private chat group with the passed [other] user.
  void createGroupChat(UserModel other) {
    sendMessage({
      "msg": "method",
      "method": "createGroupChat",
      "params": [
        {
          "_id": MainWebSocketUtil.getRandomAlphanumericWithCaps(17),
          "meetingId": _meetingInfo.meetingID,
          "userId": other.internalId,
          "clientType": "HTML5",
          "validated": true,
          "connectionId": MainWebSocketUtil.getRandomAlphanumericWithCaps(17),
          "approved": true,
          "loginTime": DateTime.now().millisecondsSinceEpoch,
          "inactivityCheck": false,
          "connectionStatus": "online",
          "sortName": other.sortName,
          "color": "#0d47a1",
          "breakoutProps": {
            "isBreakoutUser": false,
            "parentId": "bbb-none",
          },
          "effectiveConnectionType": null,
          "responseDelay": 0,
          "loggedOut": false,
          "intId": other.internalId,
          "extId": "none",
          "name": other.name,
          "role": other.role,
          "guest": false,
          "authed": true,
          "guestStatus": "ALLOW",
          "emoji": "none",
          "presenter": other.isPresenter,
          "locked": true,
          "avatar": Uri.parse(_meetingInfo.joinUrl)
              .replace(path: "/client/avatar.png")
              .toString(),
        }
      ]
    });
  }

  /// Wait until the passed send message with the passed [msgId] arrives from the main web socket as
  /// confirmation that is has been received.
  Future<void> waitForSentMsgConfirmation(String msgId) async {
    Completer<void> _completer = new Completer<void>();
    _msgConfirmCompleters[msgId] = _completer;

    return _completer.future;
  }

  @override
  void processMessage(Map<String, dynamic> msg) {
    final String method = msg["msg"];

    if (method == "added") {
      String collectionName = msg["collection"];

      if (collectionName == "group-chat-msg") {
        Map<String, dynamic> fields = msg["fields"];

        String chatID = fields["chatId"];
        DateTime timestamp =
            new DateTime.fromMillisecondsSinceEpoch(fields["timestamp"]);
        String senderID = fields["sender"];
        String content = fields["message"];
        String correlationID = fields["correlationId"];

        _onChatMessage(chatID, timestamp, senderID, content, correlationID);
      } else if (collectionName == "group-chat") {
        Map<String, dynamic> fields = msg["fields"];

        String chatID = fields["chatId"];
        String name = fields["name"];

        Set<String> participantIDs = Set();
        for (String userID in fields["users"]) {
          participantIDs.add(userID);
        }

        _onNewGroupChat(chatID, name, participantIDs);
      } else if (collectionName == "users-typing") {
        String id = msg["id"];

        Map<String, dynamic> fields = msg["fields"];

        String userID = fields["userId"];
        String name = fields["name"];
        String isTypingTo = fields["isTypingTo"];

        // Find ID of the chat we are typing to
        String chatID;
        if (isTypingTo == "public") {
          chatID = defaultChatID;
        } else {
          chatID = _chatGroups
              .firstWhere(
                  (element) => element.participantIDs.contains(isTypingTo))
              .id;
        }

        if (userID != _meetingInfo.internalUserID) {
          UserTypingInfo info = UserTypingInfo(id, chatID, userID, name);
          _usersTypingInfoMap[id] = info;

          _usersTypingMap.putIfAbsent(chatID, () => Set()).add(name);

          _userTypingStatusController.add(info);
        }
      }
    } else if (method == "removed") {
      String collectionName = msg["collection"];

      if (collectionName == "users-typing") {
        String id = msg["id"];

        // Remove typing user
        UserTypingInfo info = _usersTypingInfoMap.remove(id);
        if (info != null) {
          Set<String> usersTyping = _usersTypingMap[info.chatID];
          if (usersTyping != null) {
            usersTyping.remove(info.userName);
          }
        }

        _userTypingStatusController.add(info);
      }
    }
  }

  /// Called when a chat message has been received.
  void _onChatMessage(
    String chatID,
    DateTime timestamp,
    String senderID,
    String content,
    String correlationID,
  ) {
    if (_msgConfirmCompleters.containsKey(correlationID)) {
      Completer<void> completer = _msgConfirmCompleters.remove(correlationID);
      completer.complete(null); // Confirmation that message has been sent
    }

    ChatMessage message = ChatMessage(
      content,
      chatID: chatID,
      senderID: senderID,
      timestamp: timestamp,
    );

    _messages.putIfAbsent(chatID, () => []).add(message);
    _chatMessageController.add(message);
  }

  /// Called on a new incoming chat group.
  void _onNewGroupChat(String chatID, String name, Set<String> participantIDs) {
    ChatGroup group = ChatGroup(chatID, name, participantIDs);

    _chatGroups.add(group);
    _chatGroupController.add(group);

    // Subscribe to messages of the chat group
    List<dynamic> params = chatID != defaultChatID
        ? [_chatGroups.map((e) => "${e.id}").toList(growable: false)]
        : [];
    subscribe(_groupChatMessageTopic, params: params);
  }

  @override
  void onConnected() {
    subscribe(_groupChatTopic);
    subscribe(_usersTypingTopic);
  }

  @override
  Future<void> onDisconnect() async {
    // Close stream controllers
    _chatMessageController.close();
    _chatGroupController.close();
    _userTypingStatusController.close();

    // Complete pending message sending completers (if any)
    for (MapEntry<String, Completer<void>> entry
        in _msgConfirmCompleters.entries) {
      entry.value.completeError(
          "Chat module lost connection and thus could not receive confirmation whether a previously sent chat message has been received");
    }
  }

  /// Get a stream of incoming messages.
  Stream<ChatMessage> get messageStream => _chatMessageController.stream;

  /// Get already received messages for the passed chat ID.
  List<ChatMessage> getMessages(String chatID) =>
      _messages.putIfAbsent(chatID, () => []);

  /// Get a stream of incoming chat groups.
  Stream<ChatGroup> get chatGroupStream => _chatGroupController.stream;

  /// Get already received chat groups.
  List<ChatGroup> get chatGroups => _chatGroups;

  /// Get a stream of currently typing users.
  Stream<UserTypingInfo> get userTypingStatusStream =>
      _userTypingStatusController.stream;

  /// Get already received user typing info for the passed [chatID].
  Set<String> getUserTypingInfo(String chatID) =>
      _usersTypingMap.putIfAbsent(chatID, () => Set());
}
