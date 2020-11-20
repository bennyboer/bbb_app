import 'package:bbb_app/src/connect/meeting/main_websocket/util/util.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/video/connection/video_connection.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

enum CAMERATYPE {
  FRONT,
  BACK
}

/// Sender function for messages.
typedef MessageSender = void Function(Map<String, dynamic> msg);

class OutgoingWebcamVideoConnection extends VideoConnection {

  /// Sender to send message over the websocket with.
  MessageSender _messageSender;

  /// Camera ID of the webcam stream.
  String _cameraId;

  /// The webcam stream.
  MediaStream _localStream;

  CAMERATYPE _camtype;

  OutgoingWebcamVideoConnection(var meetingInfo, MessageSender messageSender, CAMERATYPE camtype) : super(meetingInfo) {
    _messageSender = messageSender;
    _camtype = camtype;
  }

  @override
  Future<void> init() async {
    _localStream = await _createWebcamStream();
    if(_localStream == null) {
      throw Exception("local stream was null");
    }
    return super.init();
  }

  @override
  void close() {

    _messageSender({
      "msg": "method",
      "method": "userUnshareWebcam",
      "params": [
        _cameraId,
      ],
    });

    send({
      'cameraId': _cameraId,
      'id': 'stop',
      'role': 'share',
      'type': 'video'
    });

    super.close();
    _localStream.dispose();

  }

  @override
  onPlayStart(message) {
    _messageSender({
      "msg": "method",
      "method": "userShareWebcam",
      "params": [
        _cameraId,
      ],
    });
  }

  @override
  afterCreatePeerConnection() async {
    _cameraId = meetingInfo.internalUserID + "_" + MainWebSocketUtil.getRandomHex(64);
    await pc.addStream(_localStream);
  }

  @override
  onIceCandidate(candidate) {
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
  }

  @override
  sendOffer(RTCSessionDescription s) {
    send({
      'bitrate': 200,
      'cameraId': _cameraId,
      'id': 'start',
      'meetingId': meetingInfo.meetingID,
      'record': true,
      'role': 'share',
      'sdpOffer': s.sdp,
      'type': 'video',
      'userId': meetingInfo.internalUserID,
      'userName': meetingInfo.fullUserName,
      'voiceBridge': meetingInfo.voiceBridge,
    });
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
        'facingMode': _camtype == CAMERATYPE.FRONT ? 'user' : 'environment',
        'optional': [],
      }
    };

    MediaStream stream = await navigator.mediaDevices.getUserMedia(mediaConstraints).catchError((e) {
      print("error opening webcam stream: " + e);
      return null;
    });

    return stream;
  }

}