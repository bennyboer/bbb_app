import 'dart:convert';
import 'dart:math';

import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:sip_ua/sip_ua.dart';

import 'custom_sip_ua_helper.dart';

class CallManager {
  SIPUAHelper _helper;
  MeetingInfo info;
  int _audioSessionNumber = 1;

  CallManager(this.info) {
    _helper = new CustomSIPUAHelper();
  }

  SIPUAHelper get helper => _helper;

  int get audioSessionNumber => _audioSessionNumber;

  String _getNakedUrl() {
    return Uri.parse(info.joinUrl).host;
  }

  String _buildUser() {
    return "${info.internalUserID}_$_audioSessionNumber-bbbID-${Uri.encodeComponent(info.fullUserName)}@${_getNakedUrl()}";
  }

  String _buildDisplayName() {
    return "${info.internalUserID}_$_audioSessionNumber-bbbID-${info.fullUserName}";
  }

  Uri _buildWsUri(Uri joinUrl) {
    return joinUrl
        .replace(path: "ws")
        .replace(queryParameters: {"sessionToken": info.sessionToken}).replace(
            scheme: "wss");
  }

  Map<String, dynamic> _createCookies() {
    Map<String, dynamic> cookies = new Map();
    Random r = new Random();

    cookies["Cookie"] = info.cookie
        .split(";")
        .where((element) => element.contains("JSESSIONID"))
        .first;
    String key = base64.encode(List<int>.generate(16, (_) => r.nextInt(255)));
    cookies['Sec-WebSocket-Key'] = key.toLowerCase();
    cookies['Sec-WebSocket-Protocol'] = "sip";
    cookies['Sec-WebSocket-Version'] = "13";
    cookies['Upgrade'] = "websocket";
    return cookies;
  }

  String buildEcho() {
    return "echo${info.voiceBridge}@${_getNakedUrl()}";
  }

  UaSettings buildSettings() {
    UaSettings settings = UaSettings();
    List<Map<String, String>> iceServers = [
      {'url': 'stun:stun.l.google.com:19302'}
    ];

    // TODO: The custom BBB Servers do not work sometimes
    // for (var server in info.iceServers["iceServers"]) {
    //   Map<String, String> entry = {};
    //   entry["url"] = server["url"];
    //   iceServers.add(entry);
    // }

    settings.webSocketUrl = _buildWsUri(Uri.parse(info.joinUrl)).toString();
    settings.webSocketSettings.extraHeaders = _createCookies();
    settings.webSocketSettings.allowBadCertificate = true;
    settings.webSocketSettings.userAgent = 'BigBlueButton';
    settings.iceServers = iceServers;
    settings.dtmfMode = DtmfMode.RFC2833;
    settings.displayName = _buildDisplayName();
    settings.uri = _buildUser();
    settings.userAgent = 'BigBlueButton';
    // We don't need the register message
    settings.register = false;

    _audioSessionNumber++;
    return settings;
  }
}