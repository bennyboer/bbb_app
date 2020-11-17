import 'dart:async';

import 'package:bbb_app/src/broadcast/app_state_notifier.dart';
import 'package:bbb_app/src/connect/meeting/load/exception/meeting_info_load_exception.dart';
import 'package:bbb_app/src/connect/meeting/load/meeting_info_loaders.dart';
import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:bbb_app/src/locale/app_localizations.dart';
import 'package:bbb_app/src/view/main/main_view.dart';
import 'package:bbb_app/src/view/privacy_policy/privacy_policy_view.dart';
import 'package:day_night_switcher/day_night_switcher.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

// Start view of the app where you'll be able to enter a meeting using the invitation link.
class StartView extends StatefulWidget {
  /// Text of a snackbar that should be shown when the start view has been built.
  final String _snackBarText;

  StartView({
    String snackBarText,
  }) : _snackBarText = snackBarText;

  @override
  State<StatefulWidget> createState() => _StartViewState();
}

/// State of the start view.
class _StartViewState extends State<StartView> {
  /// Duration after the user stopped typing after which to check whether
  /// an access code is needed for the current meeting URL.
  static const Duration _checkForAccessCodeNeededDuration =
      Duration(seconds: 2);

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

  /// State of the start views scaffold.
  ScaffoldState _scaffoldState;

  /// Whether the waiting room dialog is currently visible.
  bool _waitingRoomDialogShown = false;

  /// Timer of when the user stopped editing the meeting URL.
  Timer _userStoppedEditingMeetingUrlTimer;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget._snackBarText != null) {
        _scaffoldState.showSnackBar(SnackBar(
          content: Text(widget._snackBarText),
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) {
          _scaffoldState = Scaffold.of(context);

          return Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    if (MediaQuery.of(context).orientation ==
                        Orientation.portrait)
                      Image.asset(
                        "assets/icon/icon.png",
                        width: 128,
                      ),
                    if (MediaQuery.of(context).orientation ==
                        Orientation.portrait)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          AppLocalizations.of(context).get("app.title"),
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 32.0),
                        ),
                      ),
                    if (MediaQuery.of(context).orientation ==
                        Orientation.landscape)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              "assets/icon/icon.png",
                              width: 64,
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 15),
                              child: Text(
                                AppLocalizations.of(context).get("app.title"),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 32.0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    _buildForm(context),
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
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.info),
                                onPressed: () =>
                                    showAboutDialog(context: context),
                              ),
                              IconButton(
                                icon: Icon(Icons.privacy_tip),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            PrivacyPolicyView()),
                                  );
                                },
                              ),
                            ],
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
          );
        },
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
        onChanged: (url) {
          if (_userStoppedEditingMeetingUrlTimer == null) {
            _userStoppedEditingMeetingUrlTimer =
                Timer(_checkForAccessCodeNeededDuration, () {
              _handleUrlUpdate(url);
            });
          } else {
            _userStoppedEditingMeetingUrlTimer.cancel();
            _userStoppedEditingMeetingUrlTimer =
                Timer(_checkForAccessCodeNeededDuration, () {
              _handleUrlUpdate(url);
            });
          }
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

        // Check if meeting info isn't null (may happen when the waiting room dialog is cancelled).
        if (meetingInfo != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainView(meetingInfo)),
          );
        }
      } on WaitingRoomDeclinedException catch (e) {
        Scaffold.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).get("login.waiting-room-declined"),
            ),
          ),
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

  /// Try to join the meeting specified with the passed [meetingUrl], [username] and [accessCode].
  /// Will return null if cancelled.
  Future<MeetingInfo> tryJoinMeeting(
    String meetingUrl,
    String username,
    String accessCode,
  ) async {
    Completer<MeetingInfo> _completer = new Completer<MeetingInfo>();

    MeetingInfoLoaders().loader.load(
      meetingUrl,
      accessCode,
      username,
      statusUpdater: (isWaitingRoom) {
        if (isWaitingRoom) {
          _waitingRoomDialogShown = true;
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(
                    AppLocalizations.of(context).get("login.in-waiting-room")),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(),
                    ),
                    Text(AppLocalizations.of(context)
                        .get("login.in-waiting-room-message")),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text(AppLocalizations.of(context).get("cancel")),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _waitingRoomDialogShown = false;
                      _completer.complete(null);
                    },
                  ),
                ],
              );
            },
          );
        }
      },
    ).then((value) {
      if (!_completer.isCompleted) {
        _completer.complete(value);

        if (_waitingRoomDialogShown) {
          _waitingRoomDialogShown = false;
          Navigator.of(context, rootNavigator: true).pop();
        }
      }
    }).catchError((error) {
      if (!_completer.isCompleted) {
        _completer.completeError(error);

        if (_waitingRoomDialogShown) {
          _waitingRoomDialogShown = false;
          Navigator.of(context, rootNavigator: true).pop();
        }
      }
    });

    return _completer.future;
  }

  Future<void> _handleUrlUpdate(String meetingUrl) async {
    try {
      http.Response response = await http.get(meetingUrl);
      response.body.contains('room_access_code')
          ? setState(() {
              _accessCodeVisible = true;
            })
          : setState(() {
              _accessCodeVisible = false;
            });
    } catch (e) {
      // Ignore
    }
  }
}
