import 'package:bbb_app/src/view/settings/settings_view.dart';
import 'package:flutter/material.dart';

/// The main view including the current presentation/webcams/screenshare.
class MainView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MainViewState();
}

/// State of the main view.
class _MainViewState extends State<MainView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Center(
        child: Text("TODO"),
      ),
    );
  }

  /// Build the main views application bar.
  Widget _buildAppBar() => AppBar(
        title: Text("BBB"),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            tooltip: "Settings",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsView()),
              );
            },
          ),
        ],
      );
}
