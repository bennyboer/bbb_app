import 'dart:core';

import 'package:bbb_app/src/broadcast/app_state_notifier.dart';
import 'package:bbb_app/src/locale/app_localizations_delegate.dart';
import 'package:bbb_app/src/utils/log.dart';
import 'package:bbb_app/src/view/start/start_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

/// Entry point of the application.
Future main() async {
  /// Logging settings
  Log.allowVerbose = false;
  Log.allowDebug = true;

  runApp(
    ChangeNotifierProvider<AppStateNotifier>(
      create: (context) => AppStateNotifier(),
      child: BBBApp(),
    ),
  );
}

/// Main widget of the BBB app.
class BBBApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateNotifier>(
      builder: (context, appState, child) => MaterialApp(
        title: "BBB App",
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark().copyWith(
          appBarTheme: AppBarTheme(color: const Color(0xFF253341)),
          scaffoldBackgroundColor: const Color(0xFF15202B),
        ),
        themeMode: appState.darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
        home: StartView(),
        localizationsDelegates: [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizationsDelegate.supportedLocales,
      ),
    );
  }
}
