import 'dart:async';

import 'package:bbb_app/src/broadcast/module_bloc_provider.dart';
import 'package:bbb_app/src/broadcast/mute_bloc.dart';
import 'package:bbb_app/src/broadcast/user_voice_status_bloc.dart';
import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:bbb_app/src/preference/preferences.dart';
import 'package:bbb_app/src/utils/log.dart';
import 'package:sip_ua/sip_ua.dart';

import 'call_manager.dart';

/// The connection that handles the Sip call itself.
class CallConnection extends CallManager implements SipUaHelperListener {
  MeetingInfo info;
  Call _call;
  ModuleBlocProvider _provider;

  /// Whether the echo test has been done.
  bool _echoTestDone = false;

  /// Number of retries after a failed connection.
  int _retryAfterFailedCount = 0;

  /// Transport scheme currently using.
  String _currentTransportScheme;

  /// Subscription to user voice status events.
  StreamSubscription<UserVoiceStatus> _userVoiceStatusStreamSub;

  /// Subscription to mute state changes.
  StreamSubscription<MuteState> _muteEventSub;

  CallConnection(this.info, this._provider) : super(null) {
    helper.addSipUaHelperListener(this);
  }

  /// Called when the user voice status changes.
  void _onUserVoiceStatusChanged(UserVoiceStatus status) {
    if (status == UserVoiceStatus.echo_test) {
      _doEchoTest();
    } else if (status == UserVoiceStatus.connected) {
      _call.mute(true, false);

      _provider.snackbarCubit.sendSnack("audio.connected.snackbar");
    }
  }

  void connect() {
    _currentTransportScheme = Preferences().lastSuccessfulTransportSchemeForSIP;
    Log.info(
        "[VoiceConnection] Trying to connect to audio using transport scheme '$_currentTransportScheme'");

    helper.start(super.buildSettings(transportScheme: _currentTransportScheme));

    _muteEventSub = _provider.muteBloc.listen(_onMuteStateChange);
    _userVoiceStatusStreamSub =
        _provider.userVoiceStatusBloc.listen(_onUserVoiceStatusChanged);
  }

  /// Called when the mute state is changed.
  void _onMuteStateChange(MuteState state) {
    if (state == MuteState.MUTING) {
      _call.mute();
    } else if (state == MuteState.UNMUTING) {
      _call.unmute(true, false);
    }
  }

  void disconnect() {
    helper.stop();

    _muteEventSub.cancel();
    _userVoiceStatusStreamSub.cancel();
  }

  /// Attempt a reconnect.
  void reconnect({String transportScheme}) {
    _currentTransportScheme = transportScheme;
    helper.stop();
    helper.start(super.buildSettings(transportScheme: transportScheme));
  }

  @override
  void callStateChanged(Call call, CallState state) {
    Log.info("[VoiceConnection] SIP call state changed to ${state.state}");

    _call = call;
    switch (state.state) {
      case CallStateEnum.CONFIRMED:
        // Save current transport scheme as last successful transport scheme
        // for SIP call connections in the app preferences.
        Preferences().lastSuccessfulTransportSchemeForSIP =
            _currentTransportScheme;
        Log.info(
            "[CallConnection] Saved last successful transport scheme for the voice connection to '${Preferences().lastSuccessfulTransportSchemeForSIP}'");
        break;
      case CallStateEnum.MUTED:
        _provider.muteBloc.add(MuteEvent.MUTED);
        break;
      case CallStateEnum.UNMUTED:
        _provider.muteBloc.add(MuteEvent.UNMUTED);
        break;
      case CallStateEnum.FAILED:
        _provider.userVoiceStatusBloc.add(UserVoiceStatusEvent.disconnect);
        if (!_echoTestDone) {
          if (_retryAfterFailedCount <= 0) {
            _retryAfterFailedCount++;

            // Find other transport scheme to use
            String otherTransportScheme =
                _currentTransportScheme == "wss" ? "ws" : "wss";

            Log.warning(
                "[VoiceConnection] Failed before echo test has been done -> Retrying with another configuration '$otherTransportScheme'");

            _provider.snackbarCubit
                .sendSnack("audio.connection-failed.retry.snackbar");

            /*
            We experienced problems with BBB Server version 2.2.31 where
            the official web app would make the request using the WSS protocol,
            but in the SIP INVITE message it would write VIA SIP/2.0/WS instead
            of VIA SIP/2.0/WSS.
            Our implementation would always just send SIP/2.0/WSS according
            to the used protocol, which we change by setting transportScheme
            to "ws" to force it sending SIP/2.0/WS.
             */
            reconnect(transportScheme: otherTransportScheme);
          } else {
            _provider.snackbarCubit
                .sendSnack("audio.connection-failed.snackbar");
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
      helper.call(super.buildEcho(), voiceonly: true);
    }
  }

  /// Attempts to unmute the echo test
  /// (DTMF tones are the tones you hear when you press on your phone keypad)
  void _doEchoTest() {
    _call.sendDTMF("1", {"duration": 2000});
    _echoTestDone = true;
  }

  @override
  void onNewNotify(Notify ntf) {
    // TODO: implement onNewNotify
  }
}
