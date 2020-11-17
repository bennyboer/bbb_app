import 'package:bbb_app/src/connect/meeting/main_websocket/module.dart';
import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:bbb_app/src/connect/meeting/voice/call_connection.dart';

/// This Module handles Voice Stream Initialisation and sends the EchoTest end message
class CallModule extends Module {
  MeetingInfo _info;
  CallConnection _connection;

  CallModule(messageSender, this._info) : super(messageSender) {
    _connection = new CallConnection(_info, this);
  }

  @override
  void onConnected() {
    _connection.connect();
  }

  @override
  Future<void> onDisconnect() {
    _connection.disconnect();
  }

  @override
  void processMessage(Map<String, dynamic> msg) {}

  void toggleAudio() {
    _connection.toggleMute();
  }
}
