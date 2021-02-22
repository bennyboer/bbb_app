import 'dart:async';

import 'package:bbb_app/src/broadcast/module_bloc_provider.dart';
import 'package:bbb_app/src/broadcast/user_voice_status_bloc.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/module.dart';
import 'package:bbb_app/src/utils/log.dart';

const String CALL_STATE = "voiceCallStates";

/// The voice call states are only send for our user - maybe this is different
/// for other parts of the server, however we just broadcast the state so we can
/// attempt to pass the echo test as soon as the server tells us that we are connected.
class VoiceCallStatesModule extends Module {
  ModuleBlocProvider _provider;

  VoiceCallStatesModule(messageSender, this._provider) : super(messageSender);

  @override
  void onConnected() {
    subscribe("voice-call-states");
  }

  @override
  Future<void> onDisconnect() {}

  @override
  void processMessage(Map<String, dynamic> msg) {
    String collectionName = msg["collection"];
    if (collectionName != CALL_STATE) {
      return;
    }
    final Map<String, dynamic> fields = msg["fields"];

    String callStateStr = fields["callState"];

    Log.info(
        "[VoiceCallStatesModule] Noticed change in call state '$callStateStr'");

    _provider.userVoiceStatusBloc
        .add(UserVoiceStatusEventExtension.mapStringToEvent(callStateStr));
  }
}
