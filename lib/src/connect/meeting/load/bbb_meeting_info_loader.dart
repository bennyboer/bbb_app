import 'dart:io';

import 'package:bbb_app/src/connect/meeting/load/meeting_info_loader.dart';
import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;

/// Meeting info loader for BBB.
class BBBMeetingInfoLoader extends MeetingInfoLoader {
  /// Name of the token we need to parse from HTML in order to post the initial join form.
  static String _AUTHENTICITY_TOKEN_NAME = "authenticity_token";

  @override
  Future<MeetingInfo> load(String meetingUrl) async {
    String authenticityToken = await _loadAuthenticityToken(meetingUrl);

    print(authenticityToken);

    return MeetingInfo(meetingUrl, "");
  }

  /// Load the authenticity token from the given [meetingUrl].
  Future<String> _loadAuthenticityToken(String meetingUrl) async {
    // Make GET request to the meeting URL
    http.Response response = await http.get(meetingUrl);
    if (response.statusCode != HttpStatus.ok) {
      throw new Exception(
          "Request to fetch authenticity token returned unexpected status code ${response.statusCode} in the response");
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
