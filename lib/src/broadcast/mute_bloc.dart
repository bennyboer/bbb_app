import 'package:bloc/bloc.dart';

enum MuteEvent {
  /// Request muting the microphone.
  MUTE,

  /// Request unmuting the microphone.
  UNMUTE,

  /// Microphone is muted event.
  MUTED,

  /// Microphone is unmuted event.
  UNMUTED
}

enum MuteState { MUTING, UNMUTING, MUTED, UNMUTED }

class MuteBloc extends Bloc<MuteEvent, MuteState> {
  MuteBloc() : super(MuteState.MUTED);

  /// Toggle the mute status.
  void toggle() =>
      state == MuteState.MUTED ? add(MuteEvent.UNMUTE) : add(MuteEvent.MUTE);

  @override
  Stream<MuteState> mapEventToState(MuteEvent event) async* {
    switch (event) {
      case MuteEvent.MUTE:
        yield MuteState.MUTING;
        break;
      case MuteEvent.UNMUTE:
        yield MuteState.UNMUTING;
        break;
      case MuteEvent.MUTED:
        yield MuteState.MUTED;
        break;
      case MuteEvent.UNMUTED:
        yield MuteState.UNMUTED;
        break;
      default:
        addError("Event type '$event' unknown");
    }
  }
}
