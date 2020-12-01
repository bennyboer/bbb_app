import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bbb_app/src/connect/meeting/load/exception/meeting_info_load_exception.dart';
import 'package:bbb_app/src/connect/meeting/load/meeting_info_loader.dart';
import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:bbb_app/src/utils/log.dart';
import 'package:bbb_app/src/utils/websocket.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

/// Meeting info loader for BBB.
class BBBMeetingInfoLoader extends MeetingInfoLoader {
  /// Name of the token we need to parse from HTML in order to post the initial join form.
  static const String _csrfTokenName = "csrf-token";

  /// URL to poll for the current waiting room status.
  static const String _waitingRoomPollPath = "/bigbluebutton/api/guestWait";

  /// Maximum amount of polls for the current waiting room status.
  static const int _maxWaitingRoomPolls = 100;

  /// Duration to update the waiting room status after.
  static const Duration _updateWaitingRoomStatusDuration = Duration(seconds: 5);

  /// How often polled already.
  int _waitingRoomPollAttempts = 0;

  /// Cookie to use.
  String _cookie = "";

  /// Maximum amount of recursive retries for meeting not started.
  static const int _maxMeetingNotStartedRetries = 5;

  /// How many retries already executed.
  int _meetingNotStartedRetries = 0;

  /// Websocket for polling not yet started meetings.
  SimpleWebSocket _ws;

  /// Used to notify UI about not-started meeting.
  MeetingNotStartedStatusUpdater _meetingNotStartedStatusUpdater;

  @override
  Future<MeetingInfo> load(
    String meetingUrl,
    String accessCode,
    String name, {
    WaitingRoomStatusUpdater waitingRoomStatusUpdater,
    MeetingNotStartedStatusUpdater meetingNotStartedStatusUpdater,
  }) async {
    _meetingNotStartedRetries = 0;
    _waitingRoomPollAttempts = 0;

    _meetingNotStartedStatusUpdater = meetingNotStartedStatusUpdater;

    /// Gets initial csrf-token & sets the greenlight session token
    String authenticityToken = await _loadAuthenticityToken(meetingUrl);

    /// Posts the access code to url/login
    await _postLoginForm(meetingUrl, authenticityToken, accessCode);

    /// Updates csrf- and greenlight session token
    /// Simulates the redirect the server seems to expect after the insertion of a valid access code
    authenticityToken = await _loadAuthenticityToken(meetingUrl);

    /// Joins with the given name
    String initialJoinUrl =
        await _postJoinForm(meetingUrl, authenticityToken, name);

    String joinUrl = await _fetchJoinUrl(initialJoinUrl);

    // Fetch session token from the final join URL
    String sessionToken = Uri.parse(joinUrl).queryParameters["sessionToken"];

    // Check whether the initial join URL is actually the BBB waiting room
    if (_isWaitingRoom(joinUrl)) {
      waitingRoomStatusUpdater(true);

      // Wait until user has either been accepted or declined
      joinUrl = await _waitForModeratorAccept(joinUrl, sessionToken);
      if (joinUrl == null) {
        throw new WaitingRoomDeclinedException(
            "User has not been accepted by the moderator to join the meeting");
      }
    }

    // Call the "enter" endpoint to fetch all needed meeting data
    Uri parsedUri = Uri.parse(joinUrl);
    parsedUri = parsedUri.replace(path: "/bigbluebutton/api/enter");
    http.Response response =
        await http.get(parsedUri, headers: {"cookie": _cookie});
    Map<String, dynamic> enterJson = json.decode(response.body)["response"];

    Map<String, dynamic> iceServers = await _loadIceServers(joinUrl);
    Log.info("STUN / TURN servers: " + iceServers.toString());

    return MeetingInfo(
      meetingUrl: meetingUrl,
      joinUrl: joinUrl,
      sessionToken: sessionToken,
      cookie: _cookie,
      authToken: enterJson["authToken"],
      conference: enterJson["conference"],
      room: enterJson["room"],
      conferenceName: enterJson["confname"],
      fullUserName: enterJson["fullname"],
      dialNumber: enterJson["dialnumber"],
      externMeetingID: enterJson["externMeetingID"],
      externUserID: enterJson["externUserID"],
      meetingID: enterJson["meetingID"],
      internalUserID: enterJson["internalUserID"],
      role: enterJson["role"],
      logoutUrl: enterJson["logoutUrl"],
      voiceBridge: enterJson["voicebridge"],
      webVoiceConf: enterJson["webvoiceconf"],
      isBreakout: enterJson["isBreakout"],
      muteOnStart: enterJson["muteOnStart"],
      iceServers: iceServers,
    );
  }

  /// Check if the passed [joinUrl] is actually the BBB waiting room.
  bool _isWaitingRoom(String joinUrl) => joinUrl.contains("guest-wait");

  /// Wait until the moderator accepts or declines the join request.
  /// Will return the next join url when the user has been accepted by a Moderator.
  /// If the user has been denied, this method will return null.
  Future<String> _waitForModeratorAccept(
      String waitingRoomUrl, String sessionToken) async {
    Uri waitingRoomPollUrl = Uri.parse(waitingRoomUrl);
    waitingRoomPollUrl = waitingRoomPollUrl
        .replace(path: _waitingRoomPollPath, queryParameters: {
      "sessionToken": sessionToken,
      "redirect": "false",
    });

    for (_waitingRoomPollAttempts;
        _waitingRoomPollAttempts < _maxWaitingRoomPolls;
        _waitingRoomPollAttempts++) {
      http.Response response = await http.get(
        waitingRoomPollUrl,
        headers: {'Cookie': _cookie},
      );

      if (response.statusCode != HttpStatus.ok) {
        throw new Exception(
            "During waiting for the moderator accept we encountered an illegal status code: ${response.statusCode}. Expected 200 OK");
      }

      Map<String, dynamic> jsonResponse =
          json.decode(response.body)["response"];
      String guestStatus = jsonResponse["guestStatus"];
      if (guestStatus == "ALLOW") {
        return jsonResponse["url"];
      } else if (guestStatus == "DENY") {
        return null;
      }

      await Future.delayed(_updateWaitingRoomStatusDuration);
    }
  }

  /// Fetch the final join URL used to join the meeting.
  Future<String> _fetchJoinUrl(String initialJoinUrl) async {
    // Read location header from the response (using the joinURL initially) until we get a URL including the sessionToken as parameter
    String currentUrl = initialJoinUrl;
    final client = http.Client();

    var response = null;
    do {
      final request = Request('GET', Uri.parse(currentUrl))
        ..followRedirects = false;
      response = await client.send(request);
      if (response.statusCode != HttpStatus.found) {
        throw new Exception(
            "Request to join URL returned unexpected status code ${response.statusCode} in the response. Expected 302 Found.");
      }

      currentUrl = response.headers["location"];
      if (currentUrl == null) {
        throw new Exception(
            "Expected to find the join URL in the 'location' header");
      }
    } while (
        !Uri.parse(currentUrl).queryParameters.containsKey("sessionToken"));

    // Fetch cookie
    _cookie = response.headers["set-cookie"];

    return currentUrl;
  }

  Future<String> _postLoginForm(
      String meetingUrl, String authenticityToken, String accessCode) async {
    /// post login parameter to url/login
    http.Response response = await http.post(
      meetingUrl + '/login',
      headers: {'Cookie': _cookie},
      body: {
        "utf8": "true",
        "authenticity_token": authenticityToken,
        "room[access_code]": accessCode,
        "commit": "Enter",
      },
    );

    /// Set the greenlight-session cookie
    _setCookie(response);

    if (response.statusCode != HttpStatus.found) {
      throw new Exception(
          "Request to fetch join URL returned unexpected status code ${response.statusCode} in the response. Expected 302 Found.");
    }

    return "loginAttemptWentThrough";
  }

  /// Post the form to join a meeting.
  /// This method should return the concrete join URL.
  Future<String> _postJoinForm(
      String meetingUrl, String authenticityToken, String name) async {
    String path = Uri.parse(meetingUrl).path;

    http.Response response = await http.post(
      meetingUrl,
      headers: {'Cookie': _cookie},
      body: {
        "utf8": "true",
        "authenticity_token": authenticityToken,
        "$path[search]": "",
        "$path[column]": "",
        "$path[direction]": "",
        "$path[join_name]": name,
      },
    );

    _setCookie(response);

    // HTTP OK means we are not redirected to the BBB Frontend
    // --> war are waiting for the meeting to start
    if (response.statusCode == HttpStatus.ok) {
      _meetingNotStartedStatusUpdater(true);
      await _waitForMeetingToStart(meetingUrl);
      _meetingNotStartedStatusUpdater(false);
      if (_meetingNotStartedRetries < _maxMeetingNotStartedRetries) {
        _meetingNotStartedRetries++;
        return _postJoinForm(meetingUrl, authenticityToken, name);
      } else {
        Log.info(
            "Reached maximum number of retries for waiting for the meeting to start");

        throw new Exception(
            "Failed to join meeting. Meeting should already have started!");
      }
    }

    if (response.statusCode != HttpStatus.found) {
      throw new Exception(
          "Request to fetch join URL returned unexpected status code ${response.statusCode} in the response. Expected 302 Found.");
    }

    // Get join URL from the location header
    final String initialJoinUrl = response.headers["location"];
    _cookie = response.headers["set-cookie"];

    return initialJoinUrl;
  }

  /// Completes if received a message on websocket that meeting has started.
  Future<String> _waitForMeetingToStart(String meetingUrl) {
    var completer = new Completer<String>();

    String wsUrl = Uri.parse(meetingUrl)
        .replace(queryParameters: null)
        .replace(path: "/b/cable")
        .toString();
    String origin = Uri.parse(meetingUrl).origin;

    String meetingName =
        meetingUrl.split("/")[meetingUrl.split("/").length - 1];

    Map<String, String> headers = {};
    headers["Sec-WebSocket-Extensions"] =
        "permessage-deflate; client_max_window_bits";
    headers["Sec-WebSocket-Protocol"] =
        "actioncable-v1-json, actioncable-unsupported";
    headers["Origin"] =
        origin; //ActionCable requires this header. Results in 404 otherwise.

    //Create ActionCable websocket
    _ws = SimpleWebSocket(wsUrl, additionalHeaders: headers);

    _ws.onOpen = () {};

    _ws.onMessage = (message) {
      Log.info(
          "[BBBMeetingInfoLoader] Received message while waiting for the meeting to start: '$message'");

      var jsonMsg = json.decode(message);
      if (jsonMsg["type"] == "welcome") {
        Log.info(
            "[BBBMeetingInfoLoader] Received welcome message while waiting for the meeting to start");

        _ws.send(
            "{\"command\":\"subscribe\",\"identifier\":\"{\\\"channel\\\":\\\"WaitingChannel\\\",\\\"roomuid\\\":\\\"" +
                meetingName +
                "\\\",\\\"useruid\\\":\\\"anonymous\\\"}\"}");
      } else if (jsonMsg["identifier"] != null &&
          jsonMsg["message"] != null &&
          jsonMsg["identifier"].toString().contains(meetingName) &&
          jsonMsg["message"]["action"] == "started") {
        Log.info(
            "[BBBMeetingInfoLoader] The meeting the user was waiting for started");

        _ws.close();
        _ws = null;
        completer.complete("meeting started!");
      }
    };

    _ws.onClose = (int code, String reason) async {
      Log.info(
          "[BBBMeetingInfoLoader] Meeting start wait websocket closed. Reason: '$reason', code: $code");

      _ws = null;
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    };

    _ws.connect();

    return completer.future;
  }

  /// Load the authenticity token from the given [meetingUrl].
  Future<String> _loadAuthenticityToken(String meetingUrl) async {
    // Make GET request to the meeting URL, the cookie is for the second request, in the first it's empty
    http.Response response = await http.get(
      meetingUrl,
      headers: {'Cookie': _cookie},
    );
    if (response.statusCode != HttpStatus.ok) {
      throw new Exception(
          "Request to fetch authenticity token returned unexpected status code ${response.statusCode} in the response. Expected 200 OK.");
    }

    // Set the greenlight-session cookie
    _setCookie(response);

    // Parse the HTML included in the body of the response
    Document doc = parse(response.body);
    // Fetch authenticity token included in the HTML document
    Element element = doc.querySelector("meta[name=$_csrfTokenName]");

    if (element == null) {
      throw new Exception(
          "Expected to find the element containing the authenticity token in the fetched HTML");
    }

    return element.attributes["content"];
  }

  Future<Map<String, dynamic>> _loadIceServers(String joinUrl) async {
    try {

      Uri parsedUri = Uri.parse(joinUrl);
      parsedUri = parsedUri.replace(path: "/bigbluebutton/api/stuns");
      http.Response response =
          await http.get(parsedUri, headers: {"cookie": _cookie});
      Map<String, dynamic> responseJson = json.decode(response.body);

      List<dynamic> iceServers = [];

      List<dynamic> stunServers = responseJson["stunServers"];
      if(stunServers != null) {
        stunServers.forEach((e) {
          Map<String, dynamic> iceServer = _createIceServerEntry(e["url"], null, null);
          if(iceServer != null) {
            iceServers.add(iceServer);
          }
        });
      }

      List<dynamic> turnServers = responseJson["turnServers"];
      if(turnServers != null) {
        turnServers.forEach((e) {
          Map<String, dynamic> iceServer = _createIceServerEntry(e["url"], e["username"], e["password"]);
          if(iceServer != null) {
            iceServers.add(iceServer);
          }
        });
      }

      if(iceServers.isEmpty) {
        return _fallbackIceServer();
      }

      return {
        'iceServers': iceServers
      };

    } on Exception catch (e) {
      Log.error(e);
      return _fallbackIceServer();
    }
  }

  Map<String, dynamic> _fallbackIceServer() {
    return {
      'iceServers': [
        {'url': 'stun:stun.l.google.com:19302'},
      ]
    };
  }

  Map<String, dynamic> _createIceServerEntry(String url, String username, String credential) {
    Map<String, dynamic> iceServer = {};
    if(url == null) {
      return null;
    }
    iceServer["url"] = url;
    if(username != null) {
      iceServer["username"] = username;
    }
    if(credential != null) {
      iceServer["credential"] = credential;
    }
    return iceServer;
  }

  bool _setCookie(http.Response response) {
    bool success = false;
    if (response.headers["set-cookie"] != null) {
      _cookie = response.headers["set-cookie"];
      success = true;
    } else {
      Log.warning(
          "[BBBMeetingInfoLoader] Could not set the 'set-cookie' HTTP header");
    }
    return success;
  }

  @override
  void cancel() {
    Log.info(
        "[BBBMeetingInfoLoader] Cancel requested for connecting to a meeting");

    if (_ws != null) {
      _ws.close();
      _ws = null;
    }
    _meetingNotStartedRetries = _maxMeetingNotStartedRetries;
    _waitingRoomPollAttempts = _maxWaitingRoomPolls;
  }
}
