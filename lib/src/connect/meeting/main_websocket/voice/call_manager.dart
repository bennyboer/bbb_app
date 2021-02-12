import 'dart:convert';
import 'dart:math';

import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:sip_ua/sip_ua.dart';

class CallManager {
  SIPUAHelper _helper;
  MeetingInfo info;
  int _audioSessionNumber = 1;

  CallManager(this.info) {
    _helper = new SIPUAHelper();
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

  /// Build the UaSettings to use for a call.
  UaSettings buildSettings({String transportScheme}) {
    UaSettings settings = UaSettings();
    List<Map<String, String>> iceServers = [];

    for (Map<String, dynamic> server in info.iceServers["iceServers"]) {
      Map<String, String> entry = {};
      entry["url"] = server["url"];
      if (server.containsKey("username")) {
        entry["username"] = server["username"];
        entry["credential"] = server["credential"];
      }
      iceServers.add(entry);
    }

    iceServers.add({'url': 'stun:stun.l.google.com:19302'});

    settings.webSocketUrl = _buildWsUri(Uri.parse(info.joinUrl)).toString();

    settings.webSocketSettings.extraHeaders = _createCookies();
    settings.webSocketSettings.allowBadCertificate = true;
    settings.webSocketSettings.userAgent = 'BigBlueButton';

    // Use the set transport scheme (if null the protocol of the URL will be used).
    settings.webSocketSettings.transport_scheme = transportScheme;

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
