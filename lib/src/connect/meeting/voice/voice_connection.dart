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

  String _getNakedUrl() {
    return Uri.parse(info.joinUrl)
        .replace(queryParameters: null, scheme: null).toString();
  }

  String _buildUser() {
    return "${info.internalUserID}_$audioSessionNumber-${info.fullUserName}@${_getNakedUrl()}";
  }

  Uri _buildWsUri(Uri joinUrl) {
    return joinUrl.replace(path: "ws").replace(queryParameters: {"sessionToken": info.sessionToken})
        .replace(scheme: "wss");
  }

  Map<String, dynamic> _createCookies() {
    Map<String, dynamic> cookies = new Map();
    cookies["Cookie"] = info.cookie.split(";").where((element) => element.contains("JSESSIONID"));
    return cookies;
  }

  String _buildEcho() {
    return "echo${info.voiceBridge}@${_getNakedUrl()}";
  }

  void start() {
    UaSettings settings = UaSettings();

    settings.webSocketUrl = _buildWsUri(Uri.parse(info.joinUrl)).toString();
    settings.webSocketSettings.extraHeaders = _createCookies();
    settings.webSocketSettings.allowBadCertificate = true;
    settings.webSocketSettings.userAgent = 'Dart/2.8 (dart:io) for OpenSIPS.';

    settings.uri = _buildEcho();
    settings.authorizationUser = _buildUser();
    settings.displayName = info.fullUserName;
    settings.userAgent = 'Dart SIP Client v1.0.0';

    _helper.start(settings);
  }

  @override
  void callStateChanged(Call call, CallState state) {
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