import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:bbb_app/src/connect/meeting/voice/voice_manager.dart';
import 'package:sip_ua/sip_ua.dart';

class VoiceConnection extends VoiceManager implements SipUaHelperListener {
  MeetingInfo info;

  VoiceConnection(this.info) : super(null) {
    helper.addSipUaHelperListener(this);
  }

  void connect() {
    helper.start(super.buildSettings());
  }

  @override
  void callStateChanged(Call call, CallState state) {
    print("[SIP] Call state changed, is now ${state.toString()}");
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {
    print("[SIP] New Message: ${msg.toString()}");
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    print("[SIP] Registration Changed: ${state.toString()}");
  }

  @override
  void transportStateChanged(TransportState state) {
    print("[SIP] Transport Changed: ${state.toString()}");
  }
}
