import 'dart:convert';

import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
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

  //TODO custom TURN/STUN server returned by BBB
  Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'url': 'stun:stun.l.google.com:19302'},
    ]
  };

  final Map<String, dynamic> _config = {
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

  Future<void> init() {
    connect();
  }

  void close() {
    _socket.close();
    pc.close();
  }

  void connect() async {

    final uri =
    Uri.parse(meetingInfo.joinUrl).replace(path: _BBB_SFU);

    _socket = SimpleWebSocket(uri.toString());

    print('connected to ${uri.toString()}');

    _socket.onOpen = () {
      print('video connection websocket open');
      createOffer();
    };

    _socket.onMessage = (message) {
      print('received on video connection websocket: ' + message);
      try {
        onMessage(json.decode(message));
      } on FormatException catch (e) {
        print('invalid JSON received on video connection websocket: ' + message);
      }
    };

    _socket.onClose = (int code, String reason) {
      print('video connection websocket closed by server [$code => $reason]!');
    };

    await _socket.connect();
  }

  void onMessage(message) async {
    switch (message['id']) {
      case 'startResponse':
        {
          print("startResponse");
          await pc.setRemoteDescription(new RTCSessionDescription(message['sdpAnswer'], 'answer'));
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
          print("playStart");
          onPlayStart(message);
        }
        break;

      default:
        break;
    }
  }

  createOffer() async {
    try {

      pc = await createPeerConnection(_iceServers, _config);

      await afterCreatePeerConnection();

      pc.onIceCandidate = (candidate) {
        print("onIceCandidate");
        onIceCandidate(candidate);
      };

      pc.onAddStream = (stream) {
        print("onAddStream");
        onAddStream(stream);
      };

      pc.onRemoveStream = (stream) {
        print("onRemoveStream");
        onRemoveStream(stream);
      };

      RTCSessionDescription s = await pc.createOffer(_constraints);
      await pc.setLocalDescription(s);

      sendOffer(s);

    } catch (e) {
      print(e.toString());
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

  onAddStream(stream) {}

  onRemoveStream(stream) {}

  sendOffer(RTCSessionDescription s) {}

}
