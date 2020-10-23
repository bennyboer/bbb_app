import 'package:bbb_app/src/broadcast/app_state_notifier.dart';
import 'package:bbb_app/src/connect/meeting/load/meeting_info_loaders.dart';
import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:bbb_app/src/view/main/main_view.dart';
import 'package:day_night_switcher/day_night_switcher.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Start view of the app where you'll be able to enter a meeting using the invitation link.
class StartView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _StartViewState();
}

/// State of the start view.
class _StartViewState extends State<StartView> {
  /// Key of this form used to validate the form later.
  final _formKey = GlobalKey<FormState>();

  /// Controller for the meeting URL text field.
  final TextEditingController _meetingURLController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Padding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: SizedBox(), flex: 1),
              Text(
                "BigBlueButton",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32.0),
              ),
              Expanded(child: SizedBox(), flex: 1),
              Builder(builder: (context) {
                return _buildForm(context);
              }),
              Expanded(child: SizedBox(), flex: 1),
              Padding(
                padding: EdgeInsets.only(top: 5, bottom: 15),
                child: DayNightSwitcher(
                    isDarkModeEnabled:
                        Provider.of<AppStateNotifier>(context, listen: false)
                            .darkModeEnabled,
                    onStateChanged: (isDarkModeEnabled) =>
                        Provider.of<AppStateNotifier>(context, listen: false)
                            .darkModeEnabled = isDarkModeEnabled),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 15),
        ),
      ),
    );
  }

  /// Build the login form.
  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildURLTextField(),
          _buildJoinButton(context),
        ],
      ),
    );
  }

  /// Build the text field where the user should input the BBB URL to join the meeting of.
  Widget _buildURLTextField() {
    return TextFormField(
      decoration: InputDecoration(
        hintText: "BBB meeting URL",
        border: InputBorder.none,
        filled: true,
        prefixIcon: Icon(Icons.link),
      ),
      style: TextStyle(fontSize: 20.0),
      validator: (value) =>
          value.isEmpty ? "Please specify a meeting URL to join" : null,
      controller: _meetingURLController,
    );
  }

  /// Build the login button to join the meeting with when clicked.
  Widget _buildJoinButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 20),
      child: SizedBox(
        width: double.infinity,
        height: 75.0,
        child: ElevatedButton(
          onPressed: () => _submitForm(context),
          child: new Text("Join", style: TextStyle(fontSize: 20.0)),
        ),
      ),
    );
  }

  /// Submit the form and validate input fields.
  Future<void> _submitForm(BuildContext context) async {
    if (_formKey.currentState.validate()) {
      final String meetingURL = _meetingURLController.text;

      // Show a snack bar until all information to join the meeting has been loaded
      var snackBarController = Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("Trying to join the meeting..."),
      ));

      try {
        MeetingInfo meetingInfo = await tryJoinMeeting(meetingURL);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainView(meetingInfo)),
        );
      } catch (e) {
        print(e.toString()); // TODO Remove

        Scaffold.of(context).showSnackBar(
          SnackBar(content: Text("Could not join the meeting")),
        );
      }

      snackBarController.close(); // Close snack bar.
    }
  }

  /// Try to join the meeting specified with the passed [meetingUrl].
  Future<MeetingInfo> tryJoinMeeting(String meetingUrl) async {
    return await MeetingInfoLoaders().loader.load(meetingUrl, null,
        "Test user"); // TODO Include name and password in the form
  }
}
