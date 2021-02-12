import 'package:bbb_app/src/connect/meeting/main_websocket/video/connection/video_connection.dart';
import 'package:bbb_app/src/utils/log.dart';
import 'package:flutter_foreground_plugin/flutter_foreground_plugin.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class OutgoingScreenshareVideoConnection extends VideoConnection {
  /// The screenshare stream.
  MediaStream _localStream;

  OutgoingScreenshareVideoConnection(var meetingInfo) : super(meetingInfo);

  @override
  Future<void> init() async {
    _localStream = await _createScreenshareStream();
    if (_localStream == null) {
      FlutterForegroundPlugin.stopForegroundService();
      throw Exception("local stream was null");
    }
    return super.init();
  }

  @override
  void close() {
    super.close();
    _localStream.dispose();
    FlutterForegroundPlugin.stopForegroundService();
  }

  @override
  afterCreatePeerConnection() async {
    for (MediaStreamTrack track in _localStream.getTracks()) {
      await pc.addTrack(track, _localStream);
    }
  }

  @override
  onIceCandidate(candidate) {
    send({
      'callerName': meetingInfo.internalUserID,
      'id': 'iceCandidate',
      'role': 'send',
      'type': 'screenshare',
      'voiceBridge': meetingInfo.voiceBridge,
      'candidate': {
        'candidate': candidate.candidate,
        'sdpMLineIndex': candidate.sdpMlineIndex,
        'sdpMid': candidate.sdpMid,
      }
    });
  }

  @override
  sendOffer(RTCSessionDescription s) {
    send({
      'callerName': meetingInfo.internalUserID,
      'id': 'start',
      'internalMeetingId': meetingInfo.meetingID,
      'role': 'send',
      'type': 'screenshare',
      'userName': meetingInfo.fullUserName,
      'vh': 1920, //TODO
      'vw': 1080, //TODO
      'voiceBridge': meetingInfo.voiceBridge,
      'sdpOffer': s.sdp,
    });
  }

  startForegroundService() async {
    await FlutterForegroundPlugin.setServiceMethodInterval(seconds: 1);
    await FlutterForegroundPlugin.setServiceMethod(
        someDummyFunctionDoingExactlyNothing);
    await FlutterForegroundPlugin.startForegroundService(
      holdWakeLock: false,
      onStarted: () {
        Log.info("[OutgoingScreenshareVideoConnection] Foreground on Started");
      },
      onStopped: () {
        Log.info("[OutgoingScreenshareVideoConnection] Foreground on Stopped");
      },
      title: "BBB App",
      content: "BBB App Screenshare",
      iconName: "icon",
    );
    return true;
  }

  static void someDummyFunctionDoingExactlyNothing() {}

  Future<MediaStream> _createScreenshareStream() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': false,
      'video': {
        'mandatory': {
          'minFrameRate': '15',
        },
        'optional': [],
      }
    };

    await startForegroundService();

    MediaStream stream = await navigator.mediaDevices
        .getDisplayMedia(mediaConstraints)
        .catchError((e) {
      Log.error(
          "[OutgoingScreenshareVideoConnection] error opening screenshare stream: " +
              e);
      return null;
    });

    return stream;
  }
}
