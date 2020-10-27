import 'package:bbb_app/src/connect/meeting/model/user_model.dart';
import 'package:flutter/material.dart';

/// Widget showing the meeting participants and chat (or a link to the chat).
class MeetingInfoView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MeetingInfoViewState();

  MeetingInfoView(this._userMap);

  Map<String, UserModel> _userMap = {};

}

/// State of the meeting info view.
class _MeetingInfoViewState extends State<MeetingInfoView> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          ListView.builder
            (
              padding: const EdgeInsets.all(8),
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemCount: widget._userMap.length,
              itemBuilder: (BuildContext context, int index) {
                String key = widget._userMap.keys.elementAt(index);
                UserModel user = widget._userMap[key];
                if(user.connectionStatus == "online") {
                  return new Text(user.name);
                } else {
                  return new SizedBox();
                }
              }
          )
        ],
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
