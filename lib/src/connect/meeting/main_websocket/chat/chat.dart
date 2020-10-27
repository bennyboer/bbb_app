import 'dart:async';

import 'package:bbb_app/src/connect/meeting/main_websocket/chat/message.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/module.dart';
import 'package:flutter/widgets.dart';

/// BBB Chat representation.
class ChatModule extends Module {
  /// The default chat ID of the main public group chat.
  static const String defaultChatID = "MAIN-PUBLIC-GROUP-CHAT";

  /// Topic of chat messages to subscribe to.
  static const String _groupChatMessageTopic = "group-chat-msg";

  /// Controller publishing chat messages.
  StreamController<ChatMessage> _chatMessageController =
      StreamController.broadcast();

  /// Messages already received.
  List<ChatMessage> _messages = [];

  ChatModule(messageSender) : super(messageSender);

  /// Send a chat message.
  Future<void> sendGroupChatMsg({
    String chatID = defaultChatID,
    @required String internUserID,
    @required String message,
  }) async {
    // TODO
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

        ChatMessage message = ChatMessage(
          chatID: chatID,
          senderID: senderID,
          content: content,
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
