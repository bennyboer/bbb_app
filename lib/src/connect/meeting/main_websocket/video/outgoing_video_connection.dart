import 'dart:convert';

import 'package:bbb_app/src/connect/meeting/main_websocket/main_websocket.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/util/util.dart';
import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:bbb_app/src/utils/websocket.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

enum OutgoingVideoConnectionType {
  WEBCAM,
}

//TODO refactor: super class

/// Class encapsulating a WebRTC video stream connection.
class OutgoingVideoConnection {

  MainWebSocket _mainWebSocket;

  MediaStream _localStream;

  /// Info of the current meeting.
  MeetingInfo _meetingInfo;

  /// Camera ID to display stream for.
  String _cameraId;

  OutgoingVideoConnectionType _type;

  OutgoingVideoConnection(var meetingInfo, OutgoingVideoConnectionType type, MainWebSocket mainWebSocket) {
    this._meetingInfo = meetingInfo;
    this._type = type;
    this._mainWebSocket = mainWebSocket;
  }

  SimpleWebSocket _socket;
  RTCPeerConnection _pc;
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();

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
    return _localRenderer.initialize().then((value) => connect());
  }

  void close() {
    _socket.close();
    _pc.close();

    //workaround. seems like the dispose is not called properly from the ListView in main_view.dart.
    //can not dispose before RTCVideoView isn't displayed anymore. --> wait 10 seconds as this is async...
    Future.delayed(const Duration(seconds: 10), () {
      print("disposing renderer");
      _localRenderer.dispose();
    });
  }

  void connect() async {
    print("o connect!!!");

    final uri =
    Uri.parse(_meetingInfo.joinUrl).replace(path: "bbb-webrtc-sfu");

    print(uri);

    _socket = SimpleWebSocket(uri.toString());

    print('o connect to ${uri.toString()}');

    _socket.onOpen = () {
      print('o onOpen');
      createOffer();
    };

    _socket.onMessage = (message) {
      print('o Received data: ' + message);
      try {
        onMessage(json.decode(message));
      } on FormatException catch (e) {
        print('o invalid JSON received on websocket: ' + message);
      }
    };

    _socket.onClose = (int code, String reason) {
      print('o Closed by server [$code => $reason]!');
    };

    await _socket.connect();
  }

  send(data) {
    JsonEncoder encoder = new JsonEncoder();
    _socket.send(encoder.convert(data));
  }

  void onMessage(message) async {
    switch (message['id']) {
      case 'startResponse':
        {
          await _pc.setRemoteDescription(
              new RTCSessionDescription(message['sdpAnswer'], 'answer'));
        }
        break;

      case 'iceCandidate':
        {
          print("o iceCandidate");

          RTCIceCandidate candidate = new RTCIceCandidate(
              message['candidate']['candidate'],
              message['candidate']['sdpMid'],
              message['candidate']['sdpMLineIndex']);
          await _pc.addCandidate(candidate);
        }
        break;

      case 'playStart':
        {
          print("o playStart");

          print("o userShareWebcam");
          _mainWebSocket.sendMessage({
            "msg": "method",
            "method": "userShareWebcam",
            "params": [
              _cameraId,
            ],
            "id": "${_mainWebSocket.getNextCounter()}",
          });

        }
        break;

      default:
        break;
    }
  }

  createOffer() async {
    try {

      _cameraId = _meetingInfo.internalUserID + "_" + MainWebSocketUtil.getRandomHex(64);

      _localStream = await _createWebcamStream();
      _localRenderer.srcObject = _localStream;

      _pc = await createPeerConnection(_iceServers, _config);

      await _pc.addStream(_localStream);

      if(_type == OutgoingVideoConnectionType.WEBCAM) {

        _pc.onIceCandidate = (candidate) {

          print("o onIceCandidate");

          send({
            'cameraId': _cameraId,
            'candidate': {
              'candidate': candidate.candidate,
              'sdpMLineIndex': candidate.sdpMlineIndex,
              'sdpMid': candidate.sdpMid,
            },
            'id': 'onIceCandidate',
            'role': 'share',
            'type': 'video'
          });
        };
      }

      _pc.onAddStream = (stream) {
        print("o onAddStream");
        _localRenderer.srcObject = stream;
      };

      _pc.onRemoveStream = (stream) {
        print("o onRemoveStream");
        _localRenderer.srcObject = null;
      };

      RTCSessionDescription s = await _pc.createOffer(_constraints);
      await _pc.setLocalDescription(s);

      if(_type == OutgoingVideoConnectionType.WEBCAM) {
        send({
          'bitrate': 200,
          'cameraId': _cameraId,
          'id': 'start',
          'meetingId': _meetingInfo.meetingID,
          'record': true,
          'role': 'share',
          'sdpOffer': s.sdp,
          'type': 'video',
          'userId': _meetingInfo.internalUserID,
          'userName': _meetingInfo.fullUserName,
          'voiceBridge': _meetingInfo.voiceBridge,
        });
      }

    } catch (e) {
      print(e.toString());
    }
  }


  Future<MediaStream> _createWebcamStream() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': false,
      'video': {
        'mandatory': {
          'minWidth': '200', //TODO
          'minHeight': '200', //TODO
          'minFrameRate': '5', //TODO
        },
        'facingMode': 'user', //TODO
        'optional': [],
      }
    };

    MediaStream stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    return stream;
  }

  /// Get the renderer.
  RTCVideoRenderer get localRenderer => _localRenderer;

}
