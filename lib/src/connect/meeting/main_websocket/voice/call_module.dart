import 'dart:async';

import 'package:bbb_app/src/broadcast/module_bloc_provider.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/module.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/voice/call_connection.dart';
import 'package:bbb_app/src/connect/meeting/meeting_info.dart';

const String ECHO_STATE = "IN_ECHO_TEST";

/// This Module handles Voice Stream Initialisation
class CallModule extends Module {
  MeetingInfo _info;
  CallConnection _connection;
  ModuleBlocProvider _provider;

  CallModule(messageSender, this._info, this._provider) : super(messageSender) {
    _connection = new CallConnection(_info, this._provider);
  }

  @override
  void onConnected() {
    _connection.connect();
  }

  @override
  Future<void> onDisconnect() async {
    _connection.disconnect();
  }

  @override
  void processMessage(Map<String, dynamic> msg) {}

  void reconnectAudio() {
    _connection.reconnect();
  }
}
