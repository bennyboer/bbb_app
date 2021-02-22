import 'package:bbb_app/src/utils/log.dart';
import 'package:bloc/bloc.dart';

enum UserVoiceStatus { connecting, disconnected, connected, echo_test }

enum UserVoiceStatusEvent { connect, in_echo, in_conference, disconnect }

extension UserVoiceStatusEventExtension on UserVoiceStatusEvent {
  static const Map<UserVoiceStatusEvent, String> _keywords = {
    UserVoiceStatusEvent.connect: "CALL_STARTED",
    UserVoiceStatusEvent.in_echo: "IN_ECHO_TEST",
    UserVoiceStatusEvent.in_conference: "IN_CONFERENCE",
    UserVoiceStatusEvent.disconnect: "CALL_ENDED"
  };

  /// Lookup of user voice status string to a status enum.
  static Map<String, UserVoiceStatusEvent> _reverseLookup;

  String getKeyword() {
    return _keywords[this];
  }

  static UserVoiceStatusEvent mapStringToEvent(String message) {
    if (_reverseLookup == null) {
      _reverseLookup = {};
      for (var entry in _keywords.entries) {
        _reverseLookup[entry.value] = entry.key;
      }
    }

    return _reverseLookup.containsKey(message)
        ? _reverseLookup[message]
        : UserVoiceStatusEvent.disconnect;
  }
}

class UserVoiceStatusBloc extends Bloc<UserVoiceStatusEvent, UserVoiceStatus> {
  UserVoiceStatus oldStatus = UserVoiceStatus.disconnected;

  UserVoiceStatusBloc() : super(UserVoiceStatus.disconnected);

  @override
  Stream<UserVoiceStatus> mapEventToState(UserVoiceStatusEvent event) async* {
    Log.info(
        "[UserVoiceStatusBloc] Mapping event '$event' to user voice status");

    UserVoiceStatus newStatus;

    switch (event) {
      case UserVoiceStatusEvent.connect:
        newStatus = UserVoiceStatus.connecting;
        break;
      case UserVoiceStatusEvent.in_echo:
        newStatus = UserVoiceStatus.echo_test;
        break;
      case UserVoiceStatusEvent.in_conference:
        newStatus = UserVoiceStatus.connected;
        break;
      case UserVoiceStatusEvent.disconnect:
        newStatus = UserVoiceStatus.disconnected;
        break;
    }
    yield (newStatus);
    oldStatus = newStatus;
  }
}
