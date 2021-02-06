import 'dart:async';

import 'package:bbb_app/src/broadcast/ModuleBlocProvider.dart';
import 'package:bbb_app/src/broadcast/snackbar_bloc.dart';
import 'package:bbb_app/src/broadcast/user_interaction_bloc.dart';
import 'package:bbb_app/src/broadcast/user_voice_status_bloc.dart';
import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:bbb_app/src/utils/log.dart';
import 'package:sip_ua/sip_ua.dart';

import 'call_manager.dart';

/// The connection that handles the Sip call itself.
class CallConnection extends CallManager implements SipUaHelperListener {
  MeetingInfo info;
  Call _call;
  ModuleBlocProvider _provider;

  StreamSubscription<UserInteractionEvent> _subscription;

  bool _audioMuted = false;

  /// Whether the echo test has been done.
  bool _echoTestDone = false;

  /// Number of retries after a failed connection.
  int _retryAfterFailedCount = 0;

  CallConnection(this.info, this._provider) : super(null) {
    helper.addSipUaHelperListener(this);
  }

  void connect() {
    helper.start(super.buildSettings());
    _subscription = _provider.muteToggleCubit.listen(toggleMute);
  }

  void disconnect() {
    helper.stop();
    _subscription.cancel();
  }

  /// Attempt a reconnect.
  void reconnect({String transportScheme}) {
    helper.stop();
    helper.start(super.buildSettings(transportScheme: transportScheme));
  }

  void toggleMute(UserInteractionEvent event) {
    if (event == UserInteractionEvent.mute_toggle)
      if (_audioMuted) {
        _call.unmute();
      } else {
        _call.mute();
      }
  }

  @override
  void callStateChanged(Call call, CallState state) {
    Log.info("[VoiceConnection] SIP call state changed to ${state.state}");

    _call = call;
    switch (state.state) {
      case CallStateEnum.CONFIRMED:
        _call.unmute(true, false);
        _provider.snackbarCubit.sendSnack("audio.connected.snackbar");
        break;
      case CallStateEnum.MUTED:
        _audioMuted = true;
        _provider.userVoiceStatusBloc.add(UserVoiceStatusEvent.mute);
        break;
      case CallStateEnum.UNMUTED:
        _audioMuted = false;
        _provider.userVoiceStatusBloc.add(UserVoiceStatusEvent.unmute);
        break;
      case CallStateEnum.FAILED:
        _provider.userVoiceStatusBloc.add(UserVoiceStatusEvent.disconnect);
        if (!_echoTestDone) {
          if (_retryAfterFailedCount <= 0) {
            _retryAfterFailedCount++;

            Log.warning(
                "[VoiceConnection] Failed before echo test has been done -> Retrying with another configuration");

            /*
            We experienced problems with BBB Server version 2.2.31 where
            the official web app would make the request using the WSS protocol,
            but in the SIP INVITE message it would write VIA SIP/2.0/WS instead
            of VIA SIP/2.0/WSS.
            Our implementation would always just send SIP/2.0/WSS according
            to the used protocol, which we change by setting transportScheme
            to "ws" to force it sending SIP/2.0/WS.
             */
            reconnect(transportScheme: "ws");
          }
        }
        break;
      default:
    }
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {
    Log.info("[VoiceConnection] New message: '$msg'");
  }

  /// Probably useless, as we dont use registration
  @override
  void registrationStateChanged(RegistrationState state) {
    Log.info("[VoiceConnection] Registration changed to '${state.state}'");
  }

  @override
  void transportStateChanged(TransportState state) {
    Log.info("[VoiceConnection] Transport state changed to '${state.state}'");

    /// As soon as we are connected, connect to the echo call
    if (state.state == TransportStateEnum.CONNECTED) {
      helper.call(super.buildEcho(), true);
    }
  }

  /// Attempts to unmute the echo test
  /// (DTMF tones are the tones you hear when you press on your phone keypad)
  void doEchoTest() {
    _call.sendDTMF("1", {"duration": 2000});
    _echoTestDone = true;
  }
}
