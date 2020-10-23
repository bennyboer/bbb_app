import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:bbb_app/src/view/meeting_info/meeting_info_view.dart';
import 'package:bbb_app/src/view/settings/settings_view.dart';
import 'package:flutter/material.dart';

/// The main view including the current presentation/webcams/screenshare.
class MainView extends StatefulWidget {
  /// Info of the meeting to display.
  MeetingInfo _meetingInfo;

  MainView(this._meetingInfo);

  @override
  State<StatefulWidget> createState() => _MainViewState(_meetingInfo);
}

/// State of the main view.
class _MainViewState extends State<MainView> {
  /// Info of the meeting to display.
  MeetingInfo _meetingInfo;

  _MainViewState(this._meetingInfo);

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
        leading: IconButton(
          icon: Icon(Icons.people),
          tooltip: 'Meeting info',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MeetingInfoView()),
            );
          },
        ),
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
