import 'dart:async';

import 'package:bbb_app/src/broadcast/module_bloc_provider.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/chat/group.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/chat/message.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/chat/user_typing_info.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/module.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/user/model/user.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/user/user_module.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/util/util.dart';
import 'package:bbb_app/src/connect/meeting/meeting_info.dart';

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

  /// Sender ID of chat message that is sent from the BBB system itself
  /// rather than from an actual user.
  /// These messages might contain something like "Chat message has been cleared", etc.
  static const String _systemMessageSenderID = "SYSTEM_MESSAGE";

  /// System message of when the public chat has been cleared.
  static const String _systemMessagePublicChatCleared = "PUBLIC_CHAT_CLEAR";

  /// Info for the current meeting.
  final MeetingInfo _meetingInfo;

  /// User module of the main websocket connection.
  final UserModule _userModule;

  /// Provider for the module blocs.
  final ModuleBlocProvider _provider;

  /// Message counter.
  int _messageCounter = 1;

  /// Controller publishing chat messages.
  StreamController<ChatMessageEvent> _chatMessageController =
      StreamController.broadcast();

  /// Controller publishing chat groups.
  StreamController<ChatGroupEvent> _chatGroupController =
      StreamController.broadcast();

  /// Controller publishing currently typing user status updates.
  StreamController<UserTypingInfo> _userTypingStatusController =
      StreamController.broadcast();

  /// Controller publishing updated unread message counters.
  StreamController<UnreadMessageCounterEvent> _unreadMessageCounterController =
      StreamController.broadcast();

  /// Messages already received.
  Map<String, List<ChatMessage>> _messages = {};

  /// Mapping of message IDs to their chat ID.
  Map<String, String> _messageIDToChatID = {};

  /// Already received chat groups.
  List<ChatGroup> _chatGroups = [];

  /// Set of chat group IDs that are currently active (have not been removed by the user).
  Set<String> _activeChatGroups = Set();

  /// Message confirmation completer.
  Map<String, Completer<void>> _msgConfirmCompleters = {};

  /// Users currently typing (mapped per chat ID).
  Map<String, Set<String>> _usersTypingMap = {};

  /// Users currently typing info (mapped per typing message ID).
  /// Used to remove typing user status easily again.
  Map<String, UserTypingInfo> _usersTypingInfoMap = {};

  /// Counters for unread messages.
  Map<String, int> _unreadMessageCounters = {};

  /// Saved text drafts per chat ID.
  Map<String, String> _savedTextDraftsPerChatID = {};

  ChatModule(MessageSender messageSender, this._meetingInfo, this._userModule,
      this._provider)
      : super(messageSender);

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
  void createGroupChat(User other) {
    // Check if there is already a chat group with the user
    for (ChatGroup group in _chatGroups) {
      if (group.participantIDs.length == 2 &&
          group.participantIDs.contains(other.id)) {
        // Check if not in active chat groups -> then add it
        if (!_activeChatGroups.contains(group.id)) {
          _activeChatGroups.add(group.id);
          _chatGroupController.add(ChatGroupEvent(group, true));
        }
        return;
      }
    }

    sendMessage({
      "msg": "method",
      "method": "createGroupChat",
      "params": [
        {
          "_id": MainWebSocketUtil.getRandomAlphanumericWithCaps(17),
          "meetingId": _meetingInfo.meetingID,
          "userId": other.id,
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
          "intId": other.id,
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

  /// Remove the passed already existing chat [group].
  void removeGroupChat(ChatGroup group) {
    // Chat group is kept on purpose, as there is currently no way to unsubscribe to chat groups.
    // If the other participant is writing again, the chat will popup again as it is in the web client.

    // Reset unread message counter for the chat group to remove
    resetUnreadMessageCounter(group.id);

    _activeChatGroups.remove(group.id);
    _chatGroupController.add(ChatGroupEvent(group, false));
  }

  /// Reset the unread message counter for the passed [chatID].
  void resetUnreadMessageCounter(String chatID) {
    _unreadMessageCounters.putIfAbsent(chatID, () => 0);
    _unreadMessageCounters[chatID] = 0;

    _unreadMessageCounterController.add(UnreadMessageCounterEvent(chatID, 0));
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

        String id = msg["id"];
        String chatID = fields["chatId"];
        DateTime timestamp =
            new DateTime.fromMillisecondsSinceEpoch(fields["timestamp"]);
        String senderID = fields["sender"];
        String content = fields["message"];
        String correlationID = fields["correlationId"];

        _onChatMessage(id, chatID, timestamp, senderID, content, correlationID);
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

      if (collectionName == "group-chat-msg") {
        String messageID = msg["id"];

        _onChatMessageRemoval(messageID);
      } else if (collectionName == "users-typing") {
        String id = msg["id"];

        // Remove typing user
        UserTypingInfo info = _usersTypingInfoMap.remove(id);
        if (info != null) {
          Set<String> usersTyping = _usersTypingMap[info.chatID];
          if (usersTyping != null) {
            usersTyping.remove(info.userName);
          }

          _userTypingStatusController.add(info);
        }
      }
    }
  }

  /// Handle a chat message remove event for the given message [id].
  void _onChatMessageRemoval(String id) {
    // Retrieve chat ID the message belongs to
    String chatID = _messageIDToChatID[id];

    // Remove the message for this chat
    List<ChatMessage> chatMessages = _messages[chatID];

    int index = chatMessages.indexWhere((msg) => msg.messageID == id);
    if (index != -1) {
      ChatMessage msg = chatMessages.removeAt(index);

      // Publish event
      _chatMessageController.add(ChatMessageEvent(msg, false));
    }
  }

  /// Called when a chat message has been received.
  void _onChatMessage(
    String id,
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

    bool isSystemMessage = senderID == _systemMessageSenderID;
    if (isSystemMessage) {
      // Check if system message is new or just replayed when joining the meeting
      bool isNew =
          DateTime.now().toUtc().difference(timestamp.toUtc()).inSeconds <= 60;
      if (isNew) {
        if (content == _systemMessagePublicChatCleared) {
          _provider.snackbarCubit.sendSnack("chat.public-chat-cleared");
        }
      }

      return; // Do not deal with those, as they aren't real chat messages
    }

    ChatMessage message = ChatMessage(
      id,
      content,
      chatID: chatID,
      senderID: senderID,
      timestamp: timestamp,
    );

    if (!_activeChatGroups.contains(chatID)) {
      // We need to reactivate that chat group as it has been removed from the user previously.
      _activeChatGroups.add(chatID);
      _chatGroupController.add(ChatGroupEvent(
          _chatGroups.firstWhere((element) => element.id == chatID), true));
    }

    // Increase the unread message counter and publish the new counter value.
    int counter = _unreadMessageCounters.putIfAbsent(chatID, () => 0) + 1;
    _unreadMessageCounters[chatID] = counter;
    _unreadMessageCounterController
        .add(UnreadMessageCounterEvent(chatID, counter));

    _messages.putIfAbsent(chatID, () => []).add(message);
    _messageIDToChatID[id] = chatID; // Save what chat ID the message belongs to

    _chatMessageController.add(ChatMessageEvent(message, true));
  }

  /// Called on a new incoming chat group.
  void _onNewGroupChat(String chatID, String name, Set<String> participantIDs) {
    if (chatID != defaultChatID && participantIDs.length == 2) {
      // Only for private chats
      // For some reason the chat name is always the name of the other participant (even for the participant).
      String otherParticipantID = participantIDs
          .firstWhere((element) => element != _meetingInfo.internalUserID);

      name = _userModule.getUserByID(otherParticipantID).name;
    }

    ChatGroup group = ChatGroup(chatID, name, participantIDs);

    _chatGroups.add(group);
    _activeChatGroups.add(group.id);
    _chatGroupController.add(ChatGroupEvent(group, true));

    // Subscribe to messages of the chat group
    List<dynamic> params = chatID != defaultChatID
        ? [
            ["${group.id}"]
          ]
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
    _unreadMessageCounterController.close();

    // Complete pending message sending completers (if any)
    for (MapEntry<String, Completer<void>> entry
        in _msgConfirmCompleters.entries) {
      entry.value.completeError(
          "Chat module lost connection and thus could not receive confirmation whether a previously sent chat message has been received");
    }
  }

  /// Save the passed text draft for the given [chatID].
  void saveTextDraft(String chatID, String draft) {
    _savedTextDraftsPerChatID[chatID] = draft;
  }

  /// Restore a previously saved text draft for the given [chatID].
  /// Will return null if there is no draft saved.
  String restoreTextDraft(String chatID) {
    return _savedTextDraftsPerChatID.containsKey(chatID)
        ? _savedTextDraftsPerChatID[chatID]
        : null;
  }

  /// Get a stream of incoming messages.
  Stream<ChatMessageEvent> get messageStream => _chatMessageController.stream;

  /// Get already received messages for the passed chat ID.
  List<ChatMessage> getMessages(String chatID) =>
      _messages.putIfAbsent(chatID, () => []);

  /// Get a stream of incoming chat groups.
  Stream<ChatGroupEvent> get chatGroupStream => _chatGroupController.stream;

  /// Get already received chat groups.
  List<ChatGroup> get chatGroups => _chatGroups;

  /// Get a list of active chat groups (chat groups the user did not actively delete).
  List<ChatGroup> get activeChatGroups => chatGroups
      .where((element) => _activeChatGroups.contains(element.id))
      .toList(growable: false);

  /// Get a stream of currently typing users.
  Stream<UserTypingInfo> get userTypingStatusStream =>
      _userTypingStatusController.stream;

  /// Get already received user typing info for the passed [chatID].
  Set<String> getUserTypingInfo(String chatID) =>
      _usersTypingMap.putIfAbsent(chatID, () => Set());

  /// Get a stream of unread message counter updates.
  Stream<UnreadMessageCounterEvent> get unreadMessageCounterStream =>
      _unreadMessageCounterController.stream;

  /// Get a current state of a unread message counter for the passed [chatID].
  int getUnreadMessageCounter(String chatID) =>
      _unreadMessageCounters.putIfAbsent(chatID, () => 0);

  /// Get all unread message counters.
  Map<String, int> get unreadMessageCounters => _unreadMessageCounters;
}

/// Event published over the chat group stream controller.
class ChatGroupEvent {
  /// The chat group of the event.
  ChatGroup target;

  /// Whether the group has been added or removed.
  bool added;

  ChatGroupEvent(this.target, this.added);
}

/// Event published over the unread message counter stream controller.
class UnreadMessageCounterEvent {
  /// Chat ID of the chat the unread message belongs to.
  String chatID;

  /// The changed counter value.
  int counter;

  UnreadMessageCounterEvent(this.chatID, this.counter);
}

/// Event signaling that something chat-message related happened.
class ChatMessageEvent {
  /// Target the event refers to.
  ChatMessage target;

  /// Whether the chat message has been added or removed.
  bool added;

  ChatMessageEvent(this.target, this.added);
}
