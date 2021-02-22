import 'package:bbb_app/src/locale/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SnackbarCubit extends Cubit<String> {
  BuildContext _context;

  SnackbarCubit(this._context) : super("");

  void sendSnack(String key) {
    emit(AppLocalizations.of(_context).get(key));
  }
}