import 'package:bbb_app/src/connect/meeting/main_websocket/module.dart';
import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:bbb_app/src/connect/meeting/voice/voice_connection.dart';

/// This Module handles Voice Stream Initialisation and sends the EchoTest end message
class VoiceModule extends Module {
  MeetingInfo _info;
  VoiceConnection _connection;

  VoiceModule(messageSender, this._info) : super(messageSender) {
    _connection = new VoiceConnection(_info, this);
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
}
