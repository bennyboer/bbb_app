import 'dart:async';
import 'dart:io';

import 'package:bbb_app/src/connect/meeting/main_websocket/voice/call_module.dart';
import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:bbb_app/src/connect/meeting/voice/call_manager.dart';
import 'package:sip_ua/sip_ua.dart';


class CallConnection extends CallManager implements SipUaHelperListener {
  MeetingInfo info;
  CallModule _module;
  Call _call;
  bool _audioMuted = false;
  bool _secondStream = false;
  StreamController<bool> _muteStreamController = StreamController.broadcast();

  CallConnection(this.info, this._module) : super(null) {
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
      case CallStateEnum.STREAM:
        if (!_secondStream) {
          _secondStream = true;
        } else {
          // TODO! This is dirty and should be replaced by listening to the stream of voiceCallStatus
          (Call call) async {
            sleep(Duration(seconds: 3));
            call.sendDTMF("1", {"duration": 2000});
          }.call(_call);
        }
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

  Stream<bool> get callMuteStream => _muteStreamController.stream;
}
