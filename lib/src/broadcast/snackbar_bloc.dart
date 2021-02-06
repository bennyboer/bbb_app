import 'package:flutter_bloc/flutter_bloc.dart';

class SnackbarCubit extends Cubit<String> {
  SnackbarCubit() : super("");

  void sendSnack(String key) {
    emit(key);
  }
}