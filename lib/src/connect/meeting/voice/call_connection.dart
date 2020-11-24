import 'dart:async';

import 'package:bbb_app/src/connect/meeting/main_websocket/voice/call_module.dart';
import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:bbb_app/src/connect/meeting/voice/call_manager.dart';
import 'package:sip_ua/sip_ua.dart';


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
    print("[SIP] Call state changed, is now ${state.state}");
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
    print("[SIP] New Message: ${msg.toString()}");
  }

  /// Probably useless, as we dont use registration
  @override
  void registrationStateChanged(RegistrationState state) {
    print("[SIP] Registration Changed: ${state.state}");
  }

  @override
  void transportStateChanged(TransportState state) {
    print("[SIP] Transport Changed: ${state.state}");
    if (state.state == TransportStateEnum.CONNECTED) {
      helper.call(super.buildEcho(), true);
    }
  }

  /// Attempts to unmute the echo test
  void doEchoTest() {
    _call.sendDTMF("1", {"duration": 2000});
  }

  Stream<bool> get callMuteStream => _muteStreamController.stream;
}
