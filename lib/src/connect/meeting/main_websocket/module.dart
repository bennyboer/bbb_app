import 'package:bbb_app/src/connect/meeting/main_websocket/util/util.dart';

/// Sender function for messages.
typedef MessageSender = void Function(Map<String, dynamic> msg);

/// A modular part of the main websocket (Chat, participants, ...).
abstract class Module {
  /// Sender to send message over the websocket with.
  MessageSender _messageSender;

  /// Create the module.
  Module(this._messageSender);

  /// Send a message over the web socket.
  void sendMessage(Map<String, dynamic> msg) {
    _messageSender(msg);
  }

  /// Process special tasks when the web socket is connected.
  void onConnected();

  /// Process a special task when the web socket is about to be disconnected.
  Future<void> onDisconnect();

  /// Process a special task when the web socket is about to be disconnected. Executed before main websocket is closed.
  void onDisconnectBeforeWebsocketClose() {}

  /// Process an incoming message from the web socket.
  void processMessage(Map<String, dynamic> msg);

  /// Subscribe to the passed [topic].
  /// Returns the subscription ID with which we have subscribed to the topic.
  /// The subscription ID is needed to unsubscribe later.
  String subscribe(
    String topic, {
    List<dynamic> params = const [],
  }) {
    final String subscriptionID =
        MainWebSocketUtil.getRandomAlphanumericWithCaps(17);

    sendMessage({
      "msg": "sub",
      "id": subscriptionID,
      "name": topic,
      "params": params,
    });

    return subscriptionID;
  }

  /// Unsubscribe to the subscription with the passed subscription ID.
  void unsubscribe(String subscriptionID) {
    sendMessage({
      "msg": "unsub",
      "id": subscriptionID,
    });
  }

  MessageSender get messageSender => _messageSender;
}
