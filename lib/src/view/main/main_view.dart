import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:bbb_app/src/view/main/webcam/webcam_widget.dart';
import 'package:bbb_app/src/view/meeting_info/meeting_info_view.dart';
import 'package:bbb_app/src/view/settings/settings_view.dart';
import 'package:flutter/material.dart';

/// The main view including the current presentation/webcams/screenshare.
class MainView extends StatefulWidget {
  /// Info of the meeting to display.
  MeetingInfo _meetingInfo;

  MainView(this._meetingInfo);

  @override
  State<StatefulWidget> createState() => _MainViewState();

  MeetingInfo get meetingInfo => _meetingInfo;
}

/// State of the main view.
class _MainViewState extends State<MainView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Text("Your username is: ${widget.meetingInfo.fullUserName}"),
          Expanded(
            child: WebCamWidget(
              widget.meetingInfo,
              "w_gg8ddvdiitfe_LMhz0qoviCeNOkUjtcmxxhU/Qxb17tra+bhRxqwItYQ=", // TODO Find camera ID dynamically
            ),
          ),
        ],
      ),
    );
  }

  /// Build the main views application bar.
  Widget _buildAppBar() => AppBar(
        title: Text(widget.meetingInfo.conferenceName),
        leading: IconButton(
          icon: Icon(Icons.people),
          tooltip: "Meeting info",
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
