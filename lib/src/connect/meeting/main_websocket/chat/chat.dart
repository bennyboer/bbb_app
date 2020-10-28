import 'dart:async';

import 'package:bbb_app/src/connect/meeting/main_websocket/chat/message.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/module.dart';

/// BBB Chat representation.
class ChatModule extends Module {
  /// The default chat ID of the main public group chat.
  static const String defaultChatID = "MAIN-PUBLIC-GROUP-CHAT";

  /// Topic of chat messages to subscribe to.
  static const String _groupChatMessageTopic = "group-chat-msg";

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

  /// Messages already received.
  List<ChatMessage> _messages = [];

  /// Message confirmation completer.
  Map<String, Completer<void>> _msgConfirmCompleters;

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
        int timestamp = fields["timestamp"];
        String senderID = fields["sender"];
        String content = fields["message"];
        String correlationId = fields["correlationId"];

        if (_msgConfirmCompleters.containsKey(correlationId)) {
          Completer<void> completer =
              _msgConfirmCompleters.remove(correlationId);
          completer.complete(null); // Confirmation that message has been sent
        }

        ChatMessage message = ChatMessage(
          content,
          chatID: chatID,
          senderID: senderID,
          timestamp: new DateTime.fromMillisecondsSinceEpoch(timestamp),
        );

        print(
            "Incoming message: ${message.content} (From ${message.timestamp.toString()}");

        _messages.add(message);
        _chatMessageController.add(message);
      }
    }
  }

  @override
  void onConnected() {
    subscribe(_groupChatMessageTopic);
  }

  @override
  Future<void> onDisconnect() async {
    // Do nothing
  }

  /// Get a stream of incoming messages.
  Stream<ChatMessage> get messageStream => _chatMessageController.stream;

  /// Get already received messages.
  List<ChatMessage> get messages => _messages;
}
