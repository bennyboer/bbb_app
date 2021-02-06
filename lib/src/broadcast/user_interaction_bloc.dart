import 'package:bloc/bloc.dart';

enum UserInteractionEvent{ none, mute_toggle, }

class UserInteractionCubit extends Cubit<UserInteractionEvent> {
  UserInteractionCubit() : super(UserInteractionEvent.none);

  toggle() => emit(UserInteractionEvent.mute_toggle);
}