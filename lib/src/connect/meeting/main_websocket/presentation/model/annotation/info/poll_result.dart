import 'dart:math';

import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/annotation/info/annotation_info.dart';

/// Poll result annotation info.
class PollResult implements AnnotationInfo {
  /// Number of responders to the poll.
  int responders;

  /// Number of respondents to the poll.
  int respondents;

  /// Bounds of the poll result.
  Rectangle bounds;

  /// Result entries.
  List<PollResultEntry> entries;

  PollResult({
    this.responders,
    this.respondents,
    this.bounds,
    this.entries,
  });
}

/// Entry of a poll result.
class PollResultEntry {
  /// ID of the entry.
  int id;

  /// Key of the entry.
  String key;

  /// Votes on the entry.
  int votes;

  PollResultEntry({
    this.id,
    this.key,
    this.votes,
  });
}
