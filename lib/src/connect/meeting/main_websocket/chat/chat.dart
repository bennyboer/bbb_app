import 'dart:async';

import 'package:bbb_app/src/connect/meeting/main_websocket/chat/group.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/chat/message.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/module.dart';

/// BBB Chat representation.
class ChatModule extends Module {
  /// The default chat ID of the main public group chat.
  static const String defaultChatID = "MAIN-PUBLIC-GROUP-CHAT";

  /// Topic of chat messages to subscribe to.
  static const String _groupChatMessageTopic = "group-chat-msg";

  /// Topic where new group chats are published over.
  static const String _groupChatTopic = "group-chat";

  /// Maximum duration to wait until cancelling waiting for a pending message send confirmation.
  static const Duration _maxSendMsgConfirmWaitDuration = Duration(seconds: 10);

  /// Default ID of the sender (the currently logged in internal user ID).
  final String _defaultSenderId;

  /// Name of the current user.
  final String _userName;

  /// Message counter.
  int _messageCounter = 1;

  /// Controller publishing chat messages.
  StreamController<ChatMessage> _chatMessageController =
      StreamController.broadcast();

  /// Controller publishing chat groups.
  StreamController<ChatGroup> _chatGroupController =
      StreamController.broadcast();

  /// Messages already received.
  Map<String, List<ChatMessage>> _messages = {};

  /// Already received chat groups.
  List<ChatGroup> _chatGroups = [];

  /// Message confirmation completer.
  Map<String, Completer<void>> _msgConfirmCompleters = {};

  ChatModule(
    MessageSender messageSender,
    this._defaultSenderId,
    this._userName,
  ) : super(messageSender);

  /// Send a chat message.
  Future<void> sendGroupChatMsg(ChatMessage msg) async {
    final String senderID = msg.senderID ?? _defaultSenderId;

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
            "name": _userName,
          },
          "message": msg.content,
        },
      ],
    });

    return waitForSentMsgConfirmation(msgId);
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

        _onNewGroupChat(chatID, name);
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
  void _onNewGroupChat(String chatID, String name) {
    ChatGroup group = ChatGroup(chatID, name);

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
  }

  @override
  Future<void> onDisconnect() async {
    // Close stream controllers
    _chatMessageController.close();
    _chatGroupController.close();

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
  List<ChatMessage> getMessages(String chatID) => _messages[chatID];

  /// Get a stream of incoming chat groups.
  Stream<ChatGroup> get chatGroupStream => _chatGroupController.stream;

  /// Get already received chat groups.
  List<ChatGroup> get chatGroups => _chatGroups;
}
