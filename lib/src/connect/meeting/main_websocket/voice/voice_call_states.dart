import 'dart:async';

import 'package:bbb_app/src/connect/meeting/main_websocket/module.dart';

const String CALL_STATE = "voiceCallStates";

/// The voice call states are only send for our user - maybe this is different
/// for other parts of the server, however we just broadcast the state so we can
/// attempt to pass the echo test as soon as the server tells us that we are connected.
class VoiceCallStatesModule extends Module {
  String _callState;
  StreamController<String> _voiceStateStreamController =
      StreamController.broadcast();

  VoiceCallStatesModule(messageSender) : super(messageSender);

  @override
  void onConnected() {
    subscribe("voice-call-states");
  }

  @override
  Future<void> onDisconnect() {
    _voiceStateStreamController.close();
  }

  @override
  void processMessage(Map<String, dynamic> msg) {
    String collectionName = msg["collection"];
    if (collectionName != CALL_STATE) {
      return;
    }
    final Map<String, dynamic> fields = msg["fields"];
    _callState = fields["callState"];
    _voiceStateStreamController.add(_callState);
  }

  Stream<String> get voiceCallStateStream => _voiceStateStreamController.stream;
}
