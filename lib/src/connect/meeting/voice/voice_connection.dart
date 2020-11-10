import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:sip_ua/sip_ua.dart';

class VoipManager implements SipUaHelperListener {

  SIPUAHelper _helper;
  MeetingInfo info;
  int audioSessionNumber = 1;

  VoipManager(this.info) {
    _helper = new SIPUAHelper();
    _helper.addSipUaHelperListener(this);
  }

  String buildUser() {
    return "${info.internalUserID}_$audioSessionNumber-${info.fullUserName}@${Uri.parse(info.joinUrl)
        .replace(queryParameters: null)}";
  }

  void start() {
    UaSettings settings = UaSettings();

    settings.webSocketUrl = info.webVoiceConf + "?sessionToken=" + info.sessionToken;
    settings.webSocketSettings.allowBadCertificate = true;
    settings.webSocketSettings.userAgent = 'Dart/2.8 (dart:io) for OpenSIPS.';

    settings.uri = buildUser();
    settings.displayName = info.fullUserName;
    settings.userAgent = 'Dart SIP Client v1.0.0';

    _helper.start(settings);
  }

  @override
  void callStateChanged(Call call, CallState state) {
    // TODO: implement callStateChanged
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {
    // TODO: implement onNewMessage
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    // TODO: implement registrationStateChanged
  }

  @override
  void transportStateChanged(TransportState state) {
    // TODO: implement transportStateChanged
  }

}