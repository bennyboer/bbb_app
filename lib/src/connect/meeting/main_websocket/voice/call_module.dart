import 'dart:async';

import 'package:bbb_app/src/connect/meeting/main_websocket/module.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/voice/call_connection.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/voice/voice_call_states.dart';
import 'package:bbb_app/src/connect/meeting/meeting_info.dart';

const String ECHO_STATE = "IN_ECHO_TEST";

/// This Module handles Voice Stream Initialisation
class CallModule extends Module {
  MeetingInfo _info;
  CallConnection _connection;
  VoiceCallStatesModule _module;
  StreamSubscription _voiceStateSubscription;

  CallModule(messageSender, this._info, this._module) : super(messageSender) {
    _connection = new CallConnection(_info);

    _voiceStateSubscription = _module.voiceCallStateStream.listen(doCallState);
  }

  @override
  void onConnected() {
    _connection.connect();
  }

  @override
  Future<void> onDisconnect() {
    _connection.disconnect();
    _voiceStateSubscription.cancel();
  }

  @override
  void processMessage(Map<String, dynamic> msg) {}

  void doCallState(String state) {
    if (state == ECHO_STATE) {
      _connection.doEchoTest();
    }
  }

  void toggleAudio() {
    _connection.toggleMute();
  }

  void reconnectAudio() {
    _connection.reconnect();
  }

  Stream<bool> get callMuteStream => _connection.callMuteStream;
}
