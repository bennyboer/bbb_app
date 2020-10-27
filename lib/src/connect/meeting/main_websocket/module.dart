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

  /// Process an incoming message from the web socket.
  void processMessage(Map<String, dynamic> msg);
}
