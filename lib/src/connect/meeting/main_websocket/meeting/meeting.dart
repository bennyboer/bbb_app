import 'dart:async';

import 'package:bbb_app/src/connect/meeting/main_websocket/meeting/model/meeting_data.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/module.dart';

/// Module dealing with meeting information sent over the main websocket.
class MeetingModule extends Module {
  /// Topic over which the websocket publishes information regarding meetings.
  static const String _meetingsTopic = "meetings";

  /// Mapping from internal IDs to meeting IDs.
  final Map<String, String> _internalIDtoMeetingID = {};

  /// Mapping of meeting dates by their meeting ID.
  final Map<String, MeetingData> _meetings = {};

  /// Stream controller where events are published over.
  StreamController<MeetingEvent> _meetingEventStreamController =
      StreamController.broadcast();

  MeetingModule(messageSender) : super(messageSender);

  @override
  void onConnected() {
    subscribe(_meetingsTopic);
  }

  @override
  Future<void> onDisconnect() {
    _meetingEventStreamController.close();
  }

  @override
  void processMessage(Map<String, dynamic> msg) {
    final String method = msg["msg"];

    if (method == "added") {
      final String collectionName = msg["collection"];

      if (collectionName == "meetings") {
        Map<String, dynamic> fields = msg["fields"];

        MeetingData data = _jsonToMeetingData(fields);
        _meetings[data.id] = data;
        _internalIDtoMeetingID[msg["id"]] = data.id;

        _meetingEventStreamController
            .add(MeetingEvent(MeetingEventType.ADDED, data));
      }
    } else if (method == "changed") {
      final String collectionName = msg["collection"];

      if (collectionName == "meetings") {
        Map<String, dynamic> fields = msg["fields"];

        String meetingId = _internalIDtoMeetingID[msg["id"]];
        MeetingData data = _jsonToMeetingData(fields, _meetings[meetingId]);

        _meetingEventStreamController
            .add(MeetingEvent(MeetingEventType.CHANGED, data));
      }
    }
  }

  /// Convert the passed json to meeting data.
  /// Pass an old Meeting data object to update it instead of
  /// creating a new instance.
  MeetingData _jsonToMeetingData(Map<String, dynamic> fields,
      [MeetingData old]) {
    String id = fields["meetingId"];
    bool meetingEnded = fields.containsKey("meetingEnded")
        ? fields["meetingEnded"]
        : (old != null ? old.meetingEnded : false);
    bool publishedPoll = fields.containsKey("publishedPoll")
        ? fields["publishedPoll"]
        : (old != null ? old.publishedPoll : false);

    String name = (old != null ? old.name : "");
    String externalId = (old != null ? old.externalId : "");
    bool isBreakout = (old != null ? old.isBreakout : false);

    if (fields.containsKey("meetingProp")) {
      Map<String, dynamic> meetingProp = fields["meetingProp"];
      name = meetingProp.containsKey("name")
          ? meetingProp["name"]
          : (old != null ? old.name : false);
      externalId = meetingProp.containsKey("extId")
          ? meetingProp["extId"]
          : (old != null ? old.externalId : "");
      isBreakout = meetingProp.containsKey("isBreakout")
          ? meetingProp["isBreakout"]
          : (old != null ? old.isBreakout : false);
    }

    if (old != null) {
      old.name = name;
      old.meetingEnded = meetingEnded;
      old.publishedPoll = publishedPoll;
      old.isBreakout = isBreakout;
      old.externalId = externalId;

      return old;
    } else {
      return MeetingData(
        id: id,
        meetingEnded: meetingEnded,
        publishedPoll: publishedPoll,
        name: name,
        externalId: externalId,
        isBreakout: isBreakout,
      );
    }
  }

  /// Get a stream of meeting events.
  Stream<MeetingEvent> get events => _meetingEventStreamController.stream;
}

/// An event regarding meetings.
class MeetingEvent {
  /// Type of the event.
  final MeetingEventType type;

  /// Data of the meeting the event is related to.
  final MeetingData data;

  MeetingEvent(this.type, this.data);
}

/// Available meeting event types.
enum MeetingEventType { ADDED, CHANGED }
