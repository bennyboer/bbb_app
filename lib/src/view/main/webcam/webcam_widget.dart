import 'dart:convert';

import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:bbb_app/src/utils/websocket.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Widget displaying a webcam stream.
class WebCamWidget extends StatefulWidget {
  /// Info of the current meeting.
  MeetingInfo _meetingInfo;

  /// Camera ID to display stream for.
  String _cameraId;

  WebCamWidget(this._meetingInfo, this._cameraId);

  @override
  State<StatefulWidget> createState() => _WebCamWidgetState();

  String get cameraId => _cameraId;

  MeetingInfo get meetingInfo => _meetingInfo;
}

/// State of the webcam widget.
class _WebCamWidgetState extends State<WebCamWidget> {
  SimpleWebSocket _socket;
  RTCPeerConnection _pc;
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  Widget build(BuildContext context) {
        return RTCVideoView(_remoteRenderer);


  }

  @override
  void initState() {
    super.initState();

    _remoteRenderer.initialize().then((value) => connect());
  }

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
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };

  void connect() async {
    print("connect!!!");

    final uri =
        Uri.parse(widget.meetingInfo.joinUrl).replace(path: "bbb-webrtc-sfu");

    print(uri);

    _socket = SimpleWebSocket(uri.toString());

    print('connect to ${uri.toString()}');

    _socket.onOpen = () {
      print('onOpen');
      createOffer();
    };

    _socket.onMessage = (message) {
      print('Received data: ' + message);
      try {
        onMessage(json.decode(message));
      } on FormatException catch (e) {
        print('invalid JSON received on websocket: ' + message);
      }
    };

    _socket.onClose = (int code, String reason) {
      print('Closed by server [$code => $reason]!');
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
          RTCIceCandidate candidate = new RTCIceCandidate(
              message['candidate']['candidate'],
              message['candidate']['sdpMid'],
              message['candidate']['sdpMLineIndex']);
          await _pc.addCandidate(candidate);
        }
        break;

      case 'playStart':
        {
          print("############################################## playStart");
          print(_pc.getRemoteStreams());
          setState(() {_remoteRenderer.srcObject = _pc.getRemoteStreams()[1]; });
        }
        break;

      default:
        break;
    }
  }

  createOffer() async {
    try {
      _pc = await createPeerConnection(_iceServers, _config);

      _pc.onIceCandidate = (candidate) {
        send({
          'cameraId': widget.cameraId,
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMLineIndex': candidate.sdpMlineIndex,
            'sdpMid': candidate.sdpMid,
          },
          'id': 'onIceCandidate',
          'role': 'viewer',
          'type': 'video'
        });
      };

      //this is never triggered.... using case 'playStart' in onMessage() instead
      _pc.onAddStream = (stream) {
        print("############################################## onAddStream");
        _remoteRenderer.srcObject = stream;
      };

      _pc.onRemoveStream = (stream) {
        print("############################################## onRemoveStream");
        _remoteRenderer.srcObject = null;
      };

      _pc = await createPeerConnection(_iceServers, _config);

      RTCSessionDescription s = await _pc.createOffer(_constraints);
      _pc.setLocalDescription(s);

      send({
        'bitrate': 200,
        'cameraId': widget.cameraId,
        'id': 'start',
        'meetingId': widget.meetingInfo.meetingID,
        'record': true,
        'role': 'viewer',
        'sdpOffer': s.sdp,
        'type': 'video',
        'userId': widget.meetingInfo.internalUserID,
        'userName': widget.meetingInfo.fullUserName,
        'voiceBridge': widget.meetingInfo.voiceBridge,
      });
    } catch (e) {
      print(e.toString());
    }
  }
}
