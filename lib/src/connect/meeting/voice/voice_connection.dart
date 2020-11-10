import 'package:bbb_app/src/connect/meeting/main_websocket/voice/voice_module.dart';
import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:bbb_app/src/connect/meeting/voice/voice_manager.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sip_ua/sip_ua.dart';

class VoiceConnection extends VoiceManager implements SipUaHelperListener {
  MeetingInfo info;
  VoiceModule _module;
  MediaStream _localStream;
  MediaStream _remoteStream;
  bool _audioMuted = false;

  VoiceConnection(this.info, this._module) : super(null) {
    helper.addSipUaHelperListener(this);
  }

  void connect() {
    helper.start(super.buildSettings());
  }

  void _toggleMute(Call call) {
    if (_audioMuted) {
      call.unmute(true, false);
    } else {
      call.mute(true, false);
    }
    _audioMuted = !_audioMuted;
  }

  @override
  void callStateChanged(Call call, CallState state) {
    print("[SIP] Call state changed, is now ${state.state}");
    switch (state.state) {
      case CallStateEnum.CONFIRMED:
        call.unmute(true, false);
        break;
      case CallStateEnum.STREAM:
        _module.endEchoTest();
        break;
      default:
    }
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {
    print("[SIP] New Message: ${msg.toString()}");
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    print("[SIP] Registration Changed: ${state.state}");
    switch (state.state) {
      case RegistrationStateEnum.REGISTERED:
        helper.call(super.buildEcho(), true);
        break;
      case RegistrationStateEnum.REGISTRATION_FAILED:
        helper.call(super.buildEcho(), true);
        print("[SIP] Registration failed!");
        break;
      default:
    }
  }

  @override
  void transportStateChanged(TransportState state) {
    print("[SIP] Transport Changed: ${state.state}");
  }
}
