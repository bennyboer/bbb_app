import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'incoming_video_connection.dart';

class IncomingWebcamVideoConnection extends IncomingVideoConnection {
  /// Camera ID to display stream for.
  String _cameraId;

  /// ID of the user that this stream belongs to.
  String internalUserId;

  IncomingWebcamVideoConnection(meetingInfo, cameraId, userId)
      : super(meetingInfo) {
    this._cameraId = cameraId;
    this.internalUserId = userId;
  }

  @override
  onPlayStart(message) {
    remoteRenderer.srcObject = pc.getRemoteStreams()[0];
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
      'role': 'viewer',
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
      'role': 'viewer',
      'sdpOffer': s.sdp,
      'type': 'video',
      'userId': meetingInfo.internalUserID,
      'userName': meetingInfo.fullUserName,
      'voiceBridge': meetingInfo.voiceBridge,
    });
  }
}
