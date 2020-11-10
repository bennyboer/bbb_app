import 'package:sip_ua/sip_ua.dart';

import '../meeting_info.dart';

class VoiceManager {

  SIPUAHelper _helper;
  MeetingInfo info;
  int audioSessionNumber = 1;

  VoiceManager(this.info) {
    _helper = new SIPUAHelper();
  }

  SIPUAHelper get helper => _helper;

  String _getNakedUrl() {
    return Uri.parse(info.joinUrl)
        .replace(queryParameters: null, scheme: null).toString();
  }

  String _buildUser() {
    return "${info.internalUserID}_${audioSessionNumber++}-${info.fullUserName}@${_getNakedUrl()}";
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

  UaSettings buildSettings() {
    UaSettings settings = UaSettings();

    settings.webSocketUrl = _buildWsUri(Uri.parse(info.joinUrl)).toString();
    settings.webSocketSettings.extraHeaders = _createCookies();
    settings.webSocketSettings.allowBadCertificate = true;
    settings.webSocketSettings.userAgent = 'Dart/2.8 (dart:io) for OpenSIPS.';

    settings.uri = _buildEcho();
    settings.authorizationUser = _buildUser();
    settings.displayName = info.fullUserName;
    settings.userAgent = 'Dart SIP Client v1.0.0';

    return settings;
  }
}