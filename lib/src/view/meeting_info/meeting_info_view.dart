import 'package:flutter/material.dart';

/// Widget showing the meeting participants and chat (or a link to the chat).
class MeetingInfoView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MeetingInfoViewState();
}

/// State of the meeting info view.
class _MeetingInfoViewState extends State<MeetingInfoView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Center(
        child: Text("TODO: Member list, Chat (or link to chat view)"),
      ),
    );
  }

  /// Build the views application bar.
  Widget _buildAppBar() => AppBar(
      title: Text("Meeting Info"),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios),
        tooltip: "Back",
        onPressed: () {
          Navigator.pop(context);
        },
      ));
}
