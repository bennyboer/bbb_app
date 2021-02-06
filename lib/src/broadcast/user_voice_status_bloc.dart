import 'package:bloc/bloc.dart';

enum UserVoiceStatus { disconnected, echo_test, unmuted, muted }

enum UserVoiceStatusEvent { connect, in_conference, mute, unmute, disconnect }

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
        newStatus = UserVoiceStatus.echo_test;
        break;
      case UserVoiceStatusEvent.in_conference:
        if (oldStatus != UserVoiceStatus.disconnected)
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
    yield(newStatus);
    oldStatus = newStatus;
  }
  
}