import 'package:bbb_app/src/connect/meeting/main_websocket/poll/model/option.dart';

/// A poll to answer.
class Poll {
  /// Poll ID.
  final String id;

  /// Available options.
  final List<PollOption> options;

  Poll({
    this.id,
    this.options,
  });
}
