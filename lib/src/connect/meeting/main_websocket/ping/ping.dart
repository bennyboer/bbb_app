import 'dart:async';

import 'package:bbb_app/src/connect/meeting/main_websocket/module.dart';

/// Module doing the main websockets ping pong procedure.
class PingModule extends Module {
  /// Interval of the pings.
  static const Duration _pingInterval = Duration(seconds: 10);

  /// Timer for regularly sending ping message on websocket.
  Timer _pingTimer;

  PingModule(messageSender) : super(messageSender);

  @override
  void onConnected() {
    _startPing();
  }

  @override
  void processMessage(Map<String, dynamic> msg) {
    // Nothing to process
  }

  /// Regularly send a ping message to keep the connection alive.
  _startPing() {
    if (_pingTimer == null) {
      _pingTimer = new Timer.periodic(_pingInterval, (t) {
        sendMessage({
          "msg": "method",
          "method": "ping",
          "params": [],
        });
      });
    }
  }

  @override
  Future<void> onDisconnect() async {
    _pingTimer.cancel();
  }
}
