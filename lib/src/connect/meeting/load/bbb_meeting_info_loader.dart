import 'dart:convert';
import 'dart:io';

import 'package:bbb_app/src/connect/meeting/load/meeting_info_loader.dart';
import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

/// Meeting info loader for BBB.
class BBBMeetingInfoLoader extends MeetingInfoLoader {
  /// Name of the token we need to parse from HTML in order to post the initial join form.
  static String _AUTHENTICITY_TOKEN_NAME = "authenticity_token";

  /// Cookie to use.
  String _cookie = "";

  @override
  Future<MeetingInfo> load(
      String meetingUrl, String password, String name) async {
    String authenticityToken = await _loadAuthenticityToken(meetingUrl);
    String initialJoinUrl =
        await _postJoinForm(meetingUrl, authenticityToken, name);
    String joinUrl = await _fetchJoinUrl(initialJoinUrl);

    // Fetch session token from the final join URL
    String sessionToken = Uri.parse(joinUrl).queryParameters["sessionToken"];

    // Call the "enter" endpoint to fetch all needed meeting data
    Uri parsedUri = Uri.parse(joinUrl);
    parsedUri = parsedUri.replace(path: "/bigbluebutton/api/enter");
    http.Response response =
        await http.get(parsedUri, headers: {"cookie": _cookie});
    Map<String, dynamic> enterJson = json.decode(response.body)["response"];

    return MeetingInfo(
      meetingUrl: meetingUrl,
      joinUrl: joinUrl,
      sessionToken: sessionToken,
      cookie: _cookie,
      authToken: enterJson["authtoken"],
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
    );
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

  /// Post the form to join a meeting.
  /// This method should return the concrete join URL.
  Future<String> _postJoinForm(
      String meetingUrl, String authenticityToken, String name) async {
    String path = Uri.parse(meetingUrl).path;

    http.Response response = await http.post(
      meetingUrl,
      body: {
        "utf8": "true",
        "authenticity_token": authenticityToken,
        "$path[search]": "",
        "$path[column]": "",
        "$path[direction]": "",
        "$path[join_name]": name,
      },
    );
    if (response.statusCode != HttpStatus.found) {
      throw new Exception(
          "Request to fetch join URL returned unexpected status code ${response.statusCode} in the response. Expected 302 Found.");
    }

    // Get join URL from the location header
    final String initialJoinUrl = response.headers["location"];
    _cookie = response.headers["set-cookie"];

    return initialJoinUrl;
  }

  /// Load the authenticity token from the given [meetingUrl].
  Future<String> _loadAuthenticityToken(String meetingUrl) async {
    // Make GET request to the meeting URL
    http.Response response = await http.get(meetingUrl);
    if (response.statusCode != HttpStatus.ok) {
      throw new Exception(
          "Request to fetch authenticity token returned unexpected status code ${response.statusCode} in the response. Expected 200 OK.");
    }

    // Parse the HTML included in the body of the response
    Document doc = parse(response.body);

    // Fetch authenticity token included in the HTML document
    Element element =
        doc.querySelector("input[name=$_AUTHENTICITY_TOKEN_NAME]");
    if (element == null) {
      throw new Exception(
          "Expected to find the element containing the authenticity token in the fetched HTML");
    }

    return element.attributes["value"];
  }
}
