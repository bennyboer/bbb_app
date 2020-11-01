import 'dart:async';

import 'package:bbb_app/src/connect/meeting/main_websocket/module.dart';

/// Module dealing with web cam stuff.
class VideoModule extends Module {
  /// Video streams subscription topic to subscribe to.
  static const _subscriptionTopic = "video-streams";

  /// Controller over which we will publish updated camera ID lists.
  StreamController<List<String>> _videoStreamController =
      StreamController<List<String>>.broadcast();

  /// List of camera IDs we currently have.
  List<String> _cameraIDs = [];

  /// Lookup of the camera ID by a stream ID.
  Map<String, String> _cameraIdByStreamIdLookup = {};

  VideoModule(messageSender) : super(messageSender);

  @override
  void onConnected() {
    subscribe(_subscriptionTopic);
  }

  @override
  Future<void> onDisconnect() {
    _videoStreamController.close();
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

          _cameraIDs.add(cameraID);
          _cameraIdByStreamIdLookup[msg["id"]] = cameraID;

          // Publish changed camera ID list
          _videoStreamController.add(_cameraIDs);
        }
      }
    } else if (method == "removed") {
      String collectionName = msg["collection"];

      if (collectionName == "video-streams") {
        String streamID = msg["id"];
        String cameraID = _cameraIdByStreamIdLookup[streamID];

        _cameraIDs.remove(cameraID);

        // Publish changed camera ID list
        _videoStreamController.add(_cameraIDs);
      }
    }
  }

  /// Get a stream of camera IDs lists that are updated when new camera IDs pop up
  /// or are removed.
  Stream<List<String>> get cameraIDsStream => _videoStreamController.stream;

  /// Get the currently listed camera IDs.
  List<String> get cameraIDs => _cameraIDs;
}
