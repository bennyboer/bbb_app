import 'dart:convert';

import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:bbb_app/src/utils/websocket.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

enum VideoConnectionType {
  VIDEO,
  SCREENSHARE,
}

/// Class encapsulating a WebRTC video stream connection.
class VideoConnection {

  /// Info of the current meeting.
  MeetingInfo _meetingInfo;

  /// Camera ID to display stream for.
  String _cameraId;

  VideoConnectionType _type;

  VideoConnection(var meetingInfo, var cameraId, VideoConnectionType type) {
    this._meetingInfo = meetingInfo;
    this._cameraId = cameraId;
    this._type = type;
  }

  SimpleWebSocket _socket;
  RTCPeerConnection _pc;
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

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
    return _remoteRenderer.initialize().then((value) => connect());
  }

  void close() {
    _socket.close();
    _pc.close();

    //workaround. seems like the dispose is not called properly from the ListView in main_view.dart.
    //can not dispose before RTCVideoView isn't displayed anymore. --> wait 10 seconds as this is async...
    Future.delayed(const Duration(seconds: 10), () {
      print("disposing renderer");
      _remoteRenderer.dispose();
    });
  }

  void connect() async {
    print("connect!!!");

    final uri =
    Uri.parse(_meetingInfo.joinUrl).replace(path: "bbb-webrtc-sfu");

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

          if(_type == VideoConnectionType.SCREENSHARE) {
            print("screenshare stream set src!");
            _remoteRenderer.srcObject = _pc.getRemoteStreams()[0];
            print("screenshare stream set src done!");
          }

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
          print("playStart");
          print(_pc.getRemoteStreams());

          _remoteRenderer.srcObject = _pc.getRemoteStreams()[0];
        }
        break;

      default:
        break;
    }
  }

  createOffer() async {
    try {
      _pc = await createPeerConnection(_iceServers, _config);

      if(_type == VideoConnectionType.VIDEO) {

        _pc.onIceCandidate = (candidate) {
          print("onIceCandidate");

          send({
            'cameraId': _cameraId,
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
      } else if (_type == VideoConnectionType.SCREENSHARE) {
        _pc.onIceCandidate = (candidate) {
          send({
            'callerName': _meetingInfo.internalUserID,
            'candidate': {
              'candidate': candidate.candidate,
              'sdpMLineIndex': candidate.sdpMlineIndex,
              'sdpMid': candidate.sdpMid,
            },
            'id': 'iceCandidate',
            'role': 'recv',
            'type': 'screenshare',
            'voiceBridge': _meetingInfo.voiceBridge
          });
        };
      }

      //this is never triggered... using case 'playStart' in onMessage() for video streams and 'startResponse' in onMessage() for screenshare streams instead
      _pc.onAddStream = (stream) {
        print("onAddStream");
        _remoteRenderer.srcObject = stream;
      };

      _pc.onRemoveStream = (stream) {
        print("onRemoveStream");
        _remoteRenderer.srcObject = null;
      };

      RTCSessionDescription s = await _pc.createOffer(_constraints);
      _pc.setLocalDescription(s);

      if(_type == VideoConnectionType.VIDEO) {
        send({
          'bitrate': 200,
          'cameraId': _cameraId,
          'id': 'start',
          'meetingId': _meetingInfo.meetingID,
          'record': true,
          'role': 'viewer',
          'sdpOffer': s.sdp,
          'type': 'video',
          'userId': _meetingInfo.internalUserID,
          'userName': _meetingInfo.fullUserName,
          'voiceBridge': _meetingInfo.voiceBridge,
        });
      } else if(_type == VideoConnectionType.SCREENSHARE) {
        send({
          'callerName': _meetingInfo.internalUserID,
          'id': 'start',
          'internalMeetingId': _meetingInfo.meetingID,
          'role': 'recv',
          'sdpOffer': s.sdp,
          'type': 'screenshare',
          'userName': _meetingInfo.fullUserName,
          'voiceBridge': _meetingInfo.voiceBridge,
        });
      }

    } catch (e) {
      print(e.toString());
    }
  }

  /// Get the renderer.
  RTCVideoRenderer get remoteRenderer => _remoteRenderer;

}
