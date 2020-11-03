import 'dart:async';

import 'package:bbb_app/src/connect/meeting/main_websocket/module.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/poll/model/option.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/poll/model/poll.dart';

/// Module dealing with polls.
class PollModule extends Module {
  /// Topic where polls are published over.
  static const String _pollTopic = "polls";

  /// Current polls by the internal ID (not the poll ID!).
  Map<String, Poll> _pollsByID = {};

  /// Current polls by poll IDs.
  Map<String, Poll> _polls = {};

  /// Stream controller publishing polls.
  StreamController<Poll> _pollStreamController = StreamController.broadcast();

  PollModule(messageSender) : super(messageSender);

  @override
  void onConnected() {
    subscribe(_pollTopic);
  }

  @override
  Future<void> onDisconnect() {
    // Do nothing
  }

  @override
  void processMessage(Map<String, dynamic> msg) {
    final String method = msg["msg"];

    if (method == "added") {
      String collectionName = msg["collection"];

      if (collectionName == "polls") {
        String id = msg["id"];

        Map<String, dynamic> fields = msg["fields"];
        String pollId = fields["id"];

        List<dynamic> answersJson = fields["answers"];
        List<PollOption> options = [];
        for (Map<String, dynamic> answerJson in answersJson) {
          int answerId = answerJson["id"];
          String key = answerJson["key"];

          options.add(PollOption(
            id: answerId,
            key: key,
          ));
        }

        Poll poll = Poll(
          id: pollId,
          options: options,
        );

        _pollsByID[id] = poll;
        _polls[pollId] = poll;

        _pollStreamController.add(poll);
      }
    } else if (method == "changed") {
      String collectionName = msg["collection"];

      if (collectionName == "polls") {
        String id = msg["id"];

        Poll poll = _pollsByID.remove(id);
        _polls.remove(poll.id);
      }
    }
  }

  /// Vote in the poll with the given [pollId] for the option with the passed [optionId].
  void vote(String pollId, int optionId) {
    sendMessage({
      "msg": "method",
      "method": "publishVote",
      "params": [
        pollId,
        optionId,
      ],
    });
  }

  /// Get a stream of poll events.
  Stream<Poll> get pollStream => _pollStreamController.stream;
}
