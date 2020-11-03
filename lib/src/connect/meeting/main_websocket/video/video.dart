import 'dart:async';

import 'package:bbb_app/src/connect/meeting/main_websocket/module.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/video/video_connection.dart';
import 'package:bbb_app/src/connect/meeting/meeting_info.dart';

/// Module dealing with video stream stuff.
class VideoModule extends Module {

  /// Video streams subscription topic to subscribe to.
  static const _subscriptionTopic = "video-streams";

  /// Controller over which we will publish updated video connection lists.
  StreamController<Map<String, VideoConnection>> _videoConnectionsStreamController =
      StreamController<Map<String, VideoConnection>>.broadcast();

  /// List of video connections we currently have.
  Map<String, VideoConnection> _videoConnectionsByCameraId = {};

  /// Lookup of the camera ID by a stream ID.
  Map<String, String> _cameraIdByStreamIdLookup = {};

  /// Info for the current meeting.
  final MeetingInfo _meetingInfo;

  VideoModule(messageSender, this._meetingInfo,) : super(messageSender);

  @override
  void onConnected() {
    subscribe(_subscriptionTopic);
  }

  @override
  Future<void> onDisconnect() {
    _videoConnectionsStreamController.close();
    _videoConnectionsByCameraId.forEach((key, videoConnection) {
      videoConnection.close();
    });
  }

  @override
  void processMessage(Map<String, dynamic> msg) {
    final String method = msg["msg"];

    if (method == "added") {
      String collectionName = msg["collection"];

      if (collectionName == "video-streams") {
        String cameraID = msg["fields"]["stream"];
        if (cameraID != null) {
          print("Adding new video stream...");

          VideoConnection v = VideoConnection(_meetingInfo, cameraID);
          _videoConnectionsByCameraId[cameraID] = v;

          v.init().then((value) => {

            // Publish changed video connections list
            _videoConnectionsStreamController.add(_videoConnectionsByCameraId)

          });

          _cameraIdByStreamIdLookup[msg["id"]] = cameraID;

        }
      }
    } else if (method == "removed") {
      String collectionName = msg["collection"];

      if (collectionName == "video-streams") {
        print("Removing video stream...");

        String streamID = msg["id"];
        String cameraID = _cameraIdByStreamIdLookup[streamID];

        VideoConnection v = _videoConnectionsByCameraId.remove(cameraID);

        // Publish changed video connections list
        _videoConnectionsStreamController.add(_videoConnectionsByCameraId);

        v.close();
      }
    }
  }

  /// Get a stream of video connections lists that are updated when new camera IDs pop up
  /// or are removed.
  Stream<Map<String, VideoConnection>> get videoConnectionsStream => _videoConnectionsStreamController.stream;

  /// Get the currently listed video connections.
  Map<String, VideoConnection> get videoConnections => _videoConnectionsByCameraId;
}
