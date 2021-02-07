import 'package:bloc/bloc.dart';

enum UserVoiceStatus { disconnected, connected, echo_test, unmuted, muted }

enum UserVoiceStatusEvent { connect, in_echo, in_conference, mute, unmute, disconnect }

extension UserVoiceStatusEventExtension on UserVoiceStatusEvent {
  static const Map<UserVoiceStatusEvent, String> _keywords = {
    UserVoiceStatusEvent.connect: "CALL_STARTED",
    UserVoiceStatusEvent.in_echo: "IN_ECHO_TEST",
    UserVoiceStatusEvent.in_conference: "IN_CONFERENCE",
    UserVoiceStatusEvent.mute: "mute",
    UserVoiceStatusEvent.unmute: "unmute",
    UserVoiceStatusEvent.disconnect: "CALL_ENDED"
  };

  String getKeyword() {
    return _keywords[this];
  }

  static UserVoiceStatusEvent mapStringToEvent(String message) {
    if (_keywords.containsValue(message)) {
      for (var entry in _keywords.entries) {
        if (entry.value == message) {
          return entry.key;
        }
      }
    } else {
      return UserVoiceStatusEvent.disconnect;
    }
  }
}

class UserVoiceStatusBloc extends Bloc<UserVoiceStatusEvent, UserVoiceStatus> {
  UserVoiceStatus oldStatus;

  UserVoiceStatusBloc() : super(UserVoiceStatus.disconnected);

  @override
  Stream<UserVoiceStatus> mapEventToState(UserVoiceStatusEvent event) async* {
    UserVoiceStatus newStatus;

    switch (event) {
      case UserVoiceStatusEvent.connect:
        if (oldStatus != UserVoiceStatus.disconnected)
          addError("already connected -> connect update");
        newStatus = UserVoiceStatus.connected;
        break;
      case UserVoiceStatusEvent.in_echo:
        if (oldStatus != UserVoiceStatus.connected)
          addError("not connected -> echo_test update");
        newStatus = UserVoiceStatus.echo_test;
        break;
      case UserVoiceStatusEvent.in_conference:
        if (oldStatus != UserVoiceStatus.echo_test)
          addError("already connected -> in_conference update");
        newStatus = UserVoiceStatus.unmuted;
        break;
      case UserVoiceStatusEvent.mute:
        if (oldStatus == UserVoiceStatus.disconnected)
          addError("disconnected -> muted update");
        newStatus = UserVoiceStatus.unmuted;
        break;
      case UserVoiceStatusEvent.unmute:
        if (oldStatus == UserVoiceStatus.disconnected)
          addError("disconnected -> unmuted update");
        newStatus = UserVoiceStatus.unmuted;
        break;
      case UserVoiceStatusEvent.disconnect:
        newStatus = UserVoiceStatus.disconnected;
        break;
    }
    yield (newStatus);
    oldStatus = newStatus;
  }
}
