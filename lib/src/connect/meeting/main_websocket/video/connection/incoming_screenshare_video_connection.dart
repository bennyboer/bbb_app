import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'incoming_video_connection.dart';

class IncomingScreenshareVideoConnection extends IncomingVideoConnection {
  IncomingScreenshareVideoConnection(meetingInfo) : super(meetingInfo);

  @override
  onStartResponse(message) {
    remoteRenderer.srcObject = pc.getRemoteStreams()[0];
  }

  @override
  onIceCandidate(candidate) {
    send({
      'callerName': meetingInfo.internalUserID,
      'candidate': {
        'candidate': candidate.candidate,
        'sdpMLineIndex': candidate.sdpMlineIndex,
        'sdpMid': candidate.sdpMid,
      },
      'id': 'iceCandidate',
      'role': 'recv',
      'type': 'screenshare',
      'voiceBridge': meetingInfo.voiceBridge
    });
  }

  @override
  sendOffer(RTCSessionDescription s) {
    send({
      'callerName': meetingInfo.internalUserID,
      'id': 'start',
      'internalMeetingId': meetingInfo.meetingID,
      'role': 'recv',
      'sdpOffer': s.sdp,
      'type': 'screenshare',
      'userName': meetingInfo.fullUserName,
      'voiceBridge': meetingInfo.voiceBridge,
    });
  }
}
