import 'package:bbb_app/src/connect/meeting/main_websocket/util/util.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/video/connection/video_connection.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Sender function for messages.
typedef MessageSender = void Function(Map<String, dynamic> msg);

class OutgoingWebcamVideoConnection extends VideoConnection {

  /// Sender to send message over the websocket with.
  MessageSender _messageSender;

  /// Camera ID of the webcam stream.
  String _cameraId;

  /// The webcam stream.
  MediaStream _localStream;

  OutgoingWebcamVideoConnection(var meetingInfo, MessageSender messageSender) : super(meetingInfo) {
    _messageSender = messageSender;
  }

  @override
  onPlayStart(message) {
    _messageSender({
      "msg": "method",
      "method": "userShareWebcam",
      "params": [
        _cameraId,
      ],
      "id": MainWebSocketUtil.getRandomHex(32),
    });
  }

  @override
  afterCreatePeerConnection() async {
    _cameraId = meetingInfo.internalUserID + "_" + MainWebSocketUtil.getRandomHex(64);
    _localStream = await _createWebcamStream();
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
        'facingMode': 'user', //TODO
        'optional': [],
      }
    };
    MediaStream stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    return stream;
  }

}