import 'dart:convert';

import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:bbb_app/src/utils/log.dart';
import 'package:bbb_app/src/utils/websocket.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Class encapsulating a WebRTC video stream connection.
abstract class VideoConnection {
  final String _BBB_SFU = "bbb-webrtc-sfu";

  /// Info of the current meeting.
  MeetingInfo meetingInfo;

  VideoConnection(var meetingInfo) {
    this.meetingInfo = meetingInfo;
  }

  SimpleWebSocket _socket;
  RTCPeerConnection pc;

  final Map<String, dynamic> _peerConnectionConstraints = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  final Map<String, dynamic> _constraints = {
    'mandatory': {
      'OfferToReceiveAudio': false,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };

  Future<void> init() async {
    connect();
  }

  void close() {
    _socket.close();
    pc.close();
  }

  void connect() async {
    final uri = Uri.parse(meetingInfo.joinUrl).replace(path: _BBB_SFU);

    String origin = Uri.parse(meetingInfo.joinUrl).origin;
    Map<String, String> headers = {};
    headers["Origin"] = origin;

    _socket = SimpleWebSocket(uri.toString(), additionalHeaders: headers);

    Log.info("[VideoConnection] Connecting to ${uri.toString()}...");

    _socket.onOpen = () {
      Log.info("[VideoConnection] Connected");

      createOffer();
    };

    _socket.onMessage = (message) {
      Log.info("[VideoConnection] Received message: '$message'");

      try {
        onMessage(json.decode(message));
      } on FormatException catch (e) {
        Log.warning("[VideoConnection] Received invalid JSON: '$message'");
      }
    };

    _socket.onClose = (int code, String reason) {
      Log.info(
          "[VideoConnection] Connection closed. Reason: '$reason', code: $code");
    };

    await _socket.connect();
  }

  void onMessage(message) async {
    switch (message['id']) {
      case 'startResponse':
        {
          await pc.setRemoteDescription(
              new RTCSessionDescription(message['sdpAnswer'], 'answer'));
          onStartResponse(message);
        }
        break;

      case 'iceCandidate':
        {
          RTCIceCandidate candidate = new RTCIceCandidate(
              message['candidate']['candidate'],
              message['candidate']['sdpMid'],
              message['candidate']['sdpMLineIndex']);
          await pc.addCandidate(candidate);
        }
        break;

      case 'playStart':
        {
          onPlayStart(message);
        }
        break;

      default:
        break;
    }
  }

  createOffer() async {
    try {
      Map<String, dynamic> config = {"sdpSemantics": "unified-plan"};
      config.addAll(meetingInfo.iceServers);

      pc = await createPeerConnection(config, _peerConnectionConstraints);

      await afterCreatePeerConnection();

      pc.onIceCandidate = (candidate) {
        onIceCandidate(candidate);
      };

      RTCSessionDescription s = await pc.createOffer(_constraints);
      await pc.setLocalDescription(s);

      sendOffer(s);
    } catch (e) {
      Log.error(
          "[VideoConnection] Encountered an error while trying to create an offer",
          e);
    }
  }

  send(data) {
    JsonEncoder encoder = new JsonEncoder();
    _socket.send(encoder.convert(data));
  }

  onStartResponse(message) {}

  onPlayStart(message) {}

  afterCreatePeerConnection() {}

  onIceCandidate(candidate) {}

  sendOffer(RTCSessionDescription s) {}
}
