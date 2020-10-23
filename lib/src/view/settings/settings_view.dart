import 'package:bbb_app/src/broadcast/app_state_notifier.dart';
import 'package:day_night_switcher/day_night_switcher.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Widget containing the BBB apps settings (Dark mode, etc.).
class SettingsView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SettingsViewState();
}

/// State of the settings view widget.
class _SettingsViewState extends State<SettingsView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: SizedBox.expand(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DayNightSwitcher(
                isDarkModeEnabled:
                    Provider.of<AppStateNotifier>(context, listen: false)
                        .darkModeEnabled,
                onStateChanged: (isDarkModeEnabled) =>
                    Provider.of<AppStateNotifier>(context, listen: false).darkModeEnabled =
                        isDarkModeEnabled),
          ],
        ),
      ),
    );
  }
}
