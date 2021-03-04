import 'dart:async';

import 'package:bbb_app/src/broadcast/app_state_notifier.dart';
import 'package:bbb_app/src/connect/meeting/load/exception/meeting_info_load_exception.dart';
import 'package:bbb_app/src/connect/meeting/load/meeting_info_loaders.dart';
import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:bbb_app/src/locale/app_localizations.dart';
import 'package:bbb_app/src/preference/preferences.dart';
import 'package:bbb_app/src/utils/log.dart';
import 'package:bbb_app/src/view/app_notice/app_notice_widget.dart';
import 'package:bbb_app/src/view/main/main_view.dart';
import 'package:bbb_app/src/view/privacy_policy/privacy_policy_view.dart';
import 'package:bbb_app/src/view/start/start_view__text_form_field_widget.dart';
import 'package:day_night_switcher/day_night_switcher.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_links/uni_links.dart';

// Start view of the app where you'll be able to enter a meeting using the invitation link.
class StartView extends StatefulWidget {
  /// Text of a snackbar that should be shown when the start view has been built.
  final String _snackBarText;

  /// Whether to process an initial uni link (if there).
  final bool _processInitialUniLink;

  StartView({
    String snackBarText,
    bool processInitialUniLink = true,
  })  : _snackBarText = snackBarText,
        _processInitialUniLink = processInitialUniLink;

  @override
  State<StatefulWidget> createState() => _StartViewState();
}

/// State of the start view.
class _StartViewState extends State<StartView> {
  /// Access code parameter of a uni link the app has been opened with.
  static const String _uniLinkAccessCodeQueryParameter = "accessCode";

  /// Query parameter key that must exist for direct BBB join links.
  static const String _uniLinkDirectBBBLinkQueryParameter = "meetingID";

  /// Duration after the user stopped typing after which to check whether
  /// an access code is needed for the current meeting URL.
  static const Duration _checkForAccessCodeNeededDuration =
      Duration(seconds: 2);

  /// Key used to get a previously stored meeting URL from shared preferences.
  static const String _meetingURLPreferencesKey = "start_view.meeting-url";

  /// Key used to get a previously stored user name from shared preferences.
  static const String _userNamePreferencesKey = "start_view.username";

  /// Key used to get a previously stored access code from shared preferences.
  static const String _accessCodePreferencesKey = "start_view.access-code";

  /// Path to the app icon to show in the start view.
  static const String _appIconPath = "assets/icon/android/icon.png";

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

  /// Whether the meeting-not-started dialog is currently visible.
  bool _meetingNotStartedDialogShown = false;

  /// Timer of when the user stopped editing the meeting URL.
  Timer _userStoppedEditingMeetingUrlTimer;

  /// Subscription to uni link changes.
  StreamSubscription<Uri> _uniLinkSubscription;

  /// Subscription to dark mode enabled changes.
  StreamSubscription<bool> _darkModeSubscription;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();

    _darkModeSubscription =
        Preferences().darkModeEnabledChanges.listen((event) {
      Provider.of<AppStateNotifier>(context, listen: false).darkModeEnabled =
          event;
    });

    _restoreInfo();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget._snackBarText != null) {
        _scaffoldState.showSnackBar(SnackBar(
          content: Text(widget._snackBarText),
        ));
      }

      _initUniLinks();
    });
  }

  @override
  void dispose() {
    if (_uniLinkSubscription != null) _uniLinkSubscription.cancel();
    _darkModeSubscription.cancel();

    super.dispose();
  }

  /// Initialize uni links (deep linking).
  Future<void> _initUniLinks() async {
    if (widget._processInitialUniLink) {
      try {
        Uri initialLink = await getInitialUri();

        await _processUniLink(initialLink);
      } catch (e) {
        Log.warning("Deep link processing failed");
      }
    }

    _uniLinkSubscription = getUriLinksStream().listen((Uri uri) {
      _processUniLink(uri);
    });
  }

  /// Process the passed uni link.
  Future<void> _processUniLink(Uri link) async {
    if (link == null) {
      return;
    }

    Uri meetingUrl = link.replace(scheme: "https");

    bool isDirectJoinLink =
        link.queryParameters.containsKey(_uniLinkDirectBBBLinkQueryParameter);
    if (isDirectJoinLink) {
      // Join the meeting directly instead of pre-filling the fields
      try {
        await _joinMeeting(meetingUrl.toString());
      } catch (e) {
        Log.error("Could not join BBB meeting directly: '$e'");
      }
      return;
    }

    if (link.queryParameters.containsKey(_uniLinkAccessCodeQueryParameter)) {
      String accessCode =
          meetingUrl.queryParameters[_uniLinkAccessCodeQueryParameter];

      Map<String, String> newQueryParams = Map.of(meetingUrl.queryParameters);
      newQueryParams.remove(_uniLinkAccessCodeQueryParameter);
      meetingUrl = meetingUrl.replace(queryParameters: newQueryParams);

      _accessCodeVisible = true;
      _accesscodeTextField.text = accessCode;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      String newMeetingUrl = meetingUrl.toString();
      if (newMeetingUrl.endsWith("?")) {
        newMeetingUrl = newMeetingUrl.substring(0, newMeetingUrl.length - 1);
      }

      _meetingURLController.text = newMeetingUrl;
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
                    ..._buildHeaderWidgets(context),
                    _buildForm(context),
                    ..._buildFooterWidgets(context),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build the footer widgets for the start view.
  List<Widget> _buildFooterWidgets(BuildContext context) => [
        Padding(
          padding: EdgeInsets.only(top: 30, bottom: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DayNightSwitcher(
                isDarkModeEnabled:
                    Provider.of<AppStateNotifier>(context, listen: false)
                        .darkModeEnabled,
                onStateChanged: (isDarkModeEnabled) =>
                    Provider.of<AppStateNotifier>(context, listen: false)
                        .darkModeEnabled = isDarkModeEnabled,
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.info),
                    onPressed: () => showAboutDialog(context: context),
                  ),
                  IconButton(
                    icon: Icon(Icons.privacy_tip),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PrivacyPolicyView()),
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
              color:
                  Theme.of(context).textTheme.bodyText1.color.withOpacity(0.5),
              fontSize: 12.0,
            ),
          ),
        ),
        Divider(),
        Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: AppNoticeWidget(),
        ),
      ];

  /// Build the header widgets for the start view.
  List<Widget> _buildHeaderWidgets(BuildContext context) => [
        if (MediaQuery.of(context).orientation == Orientation.portrait)
          Padding(
            padding: EdgeInsets.all(20.0),
            child: Image.asset(
              _appIconPath,
              width: 128,
            ),
          ),
        if (MediaQuery.of(context).orientation == Orientation.landscape)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  _appIconPath,
                  width: 64,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 15),
                  child: Text(
                    AppLocalizations.of(context).get("app.title"),
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 32.0),
                  ),
                ),
              ],
            ),
          ),
      ];

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
    return StartViewTextFormField(
      controller: _usernameTextField,
      hintText: AppLocalizations.of(context).get("login.username"),
      prefixIcon: Icon(Icons.label),
      validator: (value) => value.isEmpty
          ? AppLocalizations.of(context).get("login.username-missing")
          : null,
    );
  }

  /// Build the accesscode text field.
  Widget _buildAccessCodeTextField() {
    return StartViewTextFormField(
      controller: _accesscodeTextField,
      hintText: AppLocalizations.of(context).get("login.accesscode"),
      prefixIcon: Icon(Icons.vpn_key),
      validator: (value) => value.isEmpty
          ? AppLocalizations.of(context).get("login.accesscode-missing")
          : null,
    );
  }

  /// Build the text field where the user should input the BBB URL to join the meeting of.
  Widget _buildURLTextField() {
    return StartViewTextFormField(
      controller: _meetingURLController,
      hintText: AppLocalizations.of(context).get("login.url"),
      prefixIcon: Icon(Icons.link),
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
      validator: (value) => value.isEmpty
          ? AppLocalizations.of(context).get("login.url-missing")
          : null,
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
      String meetingURL = _meetingURLController.text;
      final String username = _usernameTextField.text;
      final String accesscode = _accesscodeTextField.text;

      //handle input mistakes made by user
      meetingURL = meetingURL.trim();
      if (!meetingURL.startsWith("http://") &&
          !meetingURL.startsWith("https://")) {
        meetingURL = "https://" + meetingURL;
      }
      _meetingURLController.text = meetingURL;

      await _joinMeeting(
        meetingURL,
        username: username,
        accessCode: accesscode,
      );
    }
  }

  /// Join a meeting.
  Future<void> _joinMeeting(
    String meetingURL, {
    String username,
    String accessCode,
  }) async {
    // Show a snack bar until all information to join the meeting has been loaded
    var snackBarController = _scaffoldState.showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context).get("login.join-trying")),
    ));

    try {
      MeetingInfo meetingInfo =
          await tryJoinMeeting(meetingURL, username, accessCode);

      // Check if meeting info isn't null (may happen when the waiting room dialog is cancelled).
      if (meetingInfo != null) {
        // Save currently entered info to be remembered for the next login
        _saveInfo(
          meetingURL: meetingURL,
          userName: username,
          accessCode: accessCode,
        );

        // Change current view to the meeting view
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainView(meetingInfo)),
        );
      }
    } on WaitingRoomDeclinedException catch (e) {
      _scaffoldState.showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).get("login.waiting-room-declined"),
          ),
        ),
      );
    } catch (e) {
      Log.error(e);
      _scaffoldState.showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).get("login.join-failed"),
          ),
        ),
      );
    }
    snackBarController.close(); // Close snack bar.
  }

  /// Save the current info for the next time visiting the start view.
  Future<void> _saveInfo({
    String meetingURL,
    String userName,
    String accessCode,
  }) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    if (meetingURL != null) {
      sharedPreferences.setString(_meetingURLPreferencesKey, meetingURL);
    } else {
      sharedPreferences.remove(_meetingURLPreferencesKey);
    }

    if (userName != null) {
      sharedPreferences.setString(_userNamePreferencesKey, userName);
    } else {
      sharedPreferences.remove(_userNamePreferencesKey);
    }

    if (accessCode != null) {
      sharedPreferences.setString(_accessCodePreferencesKey, accessCode);
    } else {
      sharedPreferences.remove(_accessCodePreferencesKey);
    }
  }

  /// Restore the login info currently stored in shared preferences.
  Future<void> _restoreInfo() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    if (sharedPreferences.containsKey(_meetingURLPreferencesKey)) {
      this._meetingURLController.text =
          sharedPreferences.getString(_meetingURLPreferencesKey);
    }

    if (sharedPreferences.containsKey(_userNamePreferencesKey)) {
      this._usernameTextField.text =
          sharedPreferences.getString(_userNamePreferencesKey);
    }

    if (sharedPreferences.containsKey(_accessCodePreferencesKey)) {
      this._accesscodeTextField.text =
          sharedPreferences.getString(_accessCodePreferencesKey);
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

    _waitingRoomDialogShown = false;
    _meetingNotStartedDialogShown = false;

    MeetingInfoLoaders().loader.load(
      meetingUrl,
      accessCode,
      username,
      waitingRoomStatusUpdater: (isWaitingRoom) {
        if (isWaitingRoom) {
          if (_meetingNotStartedDialogShown) {
            Navigator.of(context, rootNavigator: true).pop();
            _meetingNotStartedDialogShown = false;
          }
          _waitingRoomDialogShown = true;
          showDialog(
            context: context,
            barrierDismissible: false,
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
                      MeetingInfoLoaders().loader.cancel();
                      _completer.complete(null);
                    },
                  ),
                ],
              );
            },
          );
        }
      },
      meetingNotStartedStatusUpdater: (meetingNotStarted) {
        if (meetingNotStarted) {
          _meetingNotStartedDialogShown = true;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(AppLocalizations.of(context)
                    .get("login.wait-for-meeting-to-start")),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(),
                    ),
                    Text(AppLocalizations.of(context)
                        .get("login.wait-for-meeting-to-start-message")),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text(AppLocalizations.of(context).get("cancel")),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _meetingNotStartedDialogShown = false;
                      MeetingInfoLoaders().loader.cancel();
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
        if (_meetingNotStartedDialogShown) {
          _meetingNotStartedDialogShown = false;
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
        if (_meetingNotStartedDialogShown) {
          _meetingNotStartedDialogShown = false;
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
