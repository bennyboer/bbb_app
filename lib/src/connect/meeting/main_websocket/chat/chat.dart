import 'package:bbb_app/src/connect/meeting/main_websocket/module.dart';
import 'package:flutter/widgets.dart';

/// BBB Chat representation.
class ChatModule extends Module {
  /// The default chat ID of the main public group chat.
  static const String defaultChatID = "MAIN-PUBLIC-GROUP-CHAT";

  ChatModule(messageSender) : super(messageSender);

  /// Send a chat message.
  Future<void> sendGroupChatMsg({
    String chatID = defaultChatID,
    @required String internUserID,
    @required String message,
  }) async {
    
  }

  @override
  void processMessage(Map<String, dynamic> msg) {
    // TODO: implement processMessage
  }

  @override
  void onConnected() {
    // TODO: Subscribe to the chat topic
  }
}
