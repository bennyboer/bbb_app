import 'dart:async';

import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:bbb_app/src/connect/meeting/voice/call_manager.dart';
import 'package:bbb_app/src/utils/log.dart';
import 'package:sip_ua/sip_ua.dart';

/// The connection that handles the Sip call itself.
class CallConnection extends CallManager implements SipUaHelperListener {
  MeetingInfo info;
  Call _call;
  bool _audioMuted = false;
  StreamController<bool> _muteStreamController = StreamController.broadcast();

  CallConnection(this.info) : super(null) {
    helper.addSipUaHelperListener(this);
  }

  void connect() {
    helper.start(super.buildSettings());
  }

  void disconnect() {
    helper.stop();
    _muteStreamController.close();
  }

  void toggleMute() {
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
        break;
      case CallStateEnum.MUTED:
        _audioMuted = true;
        _muteStreamController.add(_audioMuted);
        break;
      case CallStateEnum.UNMUTED:
        _audioMuted = false;
        _muteStreamController.add(_audioMuted);
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
  }

  Stream<bool> get callMuteStream => _muteStreamController.stream;
}
