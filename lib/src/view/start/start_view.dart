import 'package:bbb_app/src/broadcast/app_state_notifier.dart';
import 'package:bbb_app/src/connect/meeting/load/meeting_info_loaders.dart';
import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:bbb_app/src/locale/app_localizations.dart';
import 'package:bbb_app/src/view/main/main_view.dart';
import 'package:day_night_switcher/day_night_switcher.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
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

  /// Controller for the user name text field.
  final TextEditingController _usernameTextField = TextEditingController();

  /// Controller for the user name text field.
  final TextEditingController _accesscodeTextField = TextEditingController();

  /// Controller for the meeting URL text field.
  final TextEditingController _meetingURLController = TextEditingController();

  /// Visiblity of the access code text field.
  bool _accessCodeVisible = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    AppLocalizations.of(context).get("app.title"),
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 32.0),
                  ),
                ),
                Builder(builder: (context) {
                  return _buildForm(context);
                }),
                Padding(
                  padding: EdgeInsets.only(top: 30, bottom: 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DayNightSwitcher(
                        isDarkModeEnabled: Provider.of<AppStateNotifier>(
                                context,
                                listen: false)
                            .darkModeEnabled,
                        onStateChanged: (isDarkModeEnabled) =>
                            Provider.of<AppStateNotifier>(context,
                                    listen: false)
                                .darkModeEnabled = isDarkModeEnabled,
                      ),
                      IconButton(
                        icon: Icon(Icons.info),
                        onPressed: () => showAboutDialog(context: context),
                      ),
                    ],
                  ),
                ),
                Divider(),
                Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    AppLocalizations.of(context).get("start.bbb-trademark"),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodyText1
                          .color
                          .withOpacity(0.5),
                      fontSize: 12.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
          _buildUsernameTextField(),
          Visibility(
              visible: _accessCodeVisible, child: _buildAccessCodeTextField()),
          _buildURLTextField(),
          _buildJoinButton(context),
        ],
      ),
    );
  }

  /// Build the user name text field.
  Widget _buildUsernameTextField() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: TextFormField(
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).get("login.username"),
          border: InputBorder.none,
          filled: true,
          prefixIcon: Icon(Icons.label),
        ),
        style: TextStyle(fontSize: 20.0),
        validator: (value) => value.isEmpty
            ? AppLocalizations.of(context).get("login.username-missing")
            : null,
        controller: _usernameTextField,
      ),
    );
  }

  /// Build the accesscode text field.
  Widget _buildAccessCodeTextField() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: TextFormField(
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).get("login.accesscode"),
          border: InputBorder.none,
          filled: true,
          prefixIcon: Icon(Icons.vpn_key),
        ),
        style: TextStyle(fontSize: 20.0),
        validator: (value) => value.isEmpty
            ? AppLocalizations.of(context).get("login.accesscode-missing")
            : null,
        controller: _accesscodeTextField,
      ),
    );
  }

  /// Build the text field where the user should input the BBB URL to join the meeting of.
  Widget _buildURLTextField() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: TextFormField(
        onChanged: (url) async {
          _handleUrlUpdate(url);
        },
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).get("login.url"),
          border: InputBorder.none,
          filled: true,
          prefixIcon: Icon(Icons.link),
        ),
        style: TextStyle(fontSize: 20.0),
        validator: (value) => value.isEmpty
            ? AppLocalizations.of(context).get("login.url-missing")
            : null,
        controller: _meetingURLController,
      ),
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
          child: new Text(
            AppLocalizations.of(context).get("login.join"),
            style: TextStyle(fontSize: 20.0),
          ),
        ),
      ),
    );
  }

  /// Submit the form and validate input fields.
  Future<void> _submitForm(BuildContext context) async {
    if (_formKey.currentState.validate()) {
      final String meetingURL = _meetingURLController.text;
      final String username = _usernameTextField.text;
      final String accesscode = _accesscodeTextField.text;

      // Show a snack bar until all information to join the meeting has been loaded
      var snackBarController = Scaffold.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).get("login.join-trying")),
      ));

      try {
        MeetingInfo meetingInfo =
            await tryJoinMeeting(meetingURL, username, accesscode);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainView(meetingInfo)),
        );
      } catch (e) {
        Scaffold.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).get("login.join-failed"),
            ),
          ),
        );
      }
      snackBarController.close(); // Close snack bar.
    }
  }

  /// Try to join the meeting specified with the passed [meetingUrl], [username] and [accesscode].
  Future<MeetingInfo> tryJoinMeeting(
      String meetingUrl, String username, String accesscode) async {
    return await MeetingInfoLoaders()
        .loader
        .load(meetingUrl, accesscode, username);
  }

  Future<void> _handleUrlUpdate(String meetingUrl) async {
    /// Only send out a request to urls of the form "https://*/x/xxx-xxx-xxx-xxx"
    // ^https://(?!.*://.+) -> Match if starts with https://, not followed by ://
    // excluding spaces [^ ]+ and ignore chracters till string ends with pattern /x/xxx-xxx-xxx-xxx
    if (meetingUrl.contains(new RegExp(
        r'^https://(?!.*://.+)[^ ]+/[a-z0-9]/([a-z0-9]{3}-){3}[a-z0-9]{3}$'))) {
      http.Response response = await http.get(meetingUrl);
      response.body.contains('room_access_code')
          ? setState(() {
              _accessCodeVisible = true;
            })
          : setState(() {
              _accessCodeVisible = false;
            });
    }
  }
}
