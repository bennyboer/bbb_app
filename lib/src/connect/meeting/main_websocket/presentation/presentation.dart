import 'package:bbb_app/src/connect/meeting/main_websocket/module.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/conversion_status.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/presentation_page.dart';

import 'model/presentation.dart';

/// Module providing presentation-related stuff.
class PresentationModule extends Module {
  PresentationModule(messageSender) : super(messageSender);

  @override
  void onConnected() {
    // TODO: implement onConnected
  }

  @override
  Future<void> onDisconnect() {
    // TODO: implement onDisconnect
    throw UnimplementedError();
  }

  @override
  void processMessage(Map<String, dynamic> msg) {
    final String method = msg["msg"];

    if (method == "added") {
      String collectionName = msg["collection"];

      if (collectionName == "presentations") {
        Map<String, dynamic> fields = msg["fields"];

        Presentation presentation = _jsonToPresentation(fields);
      }
    }
  }

  /// Convert the passed JSON to a presentation.
  Presentation _jsonToPresentation(Map<String, dynamic> fields) {
    String id = fields["id"];
    String podId = fields["podId"];
    String name = fields["name"];
    bool current = fields["current"];
    bool downloadable = fields["downloadable"];

    Map<String, dynamic> conversion = fields["conversion"];
    ConversionStatus conversionStatus = _jsonToConversionStatus(conversion);

    List<Map<String, dynamic>> jsonPages = fields["pages"];
    List<PresentationPage> pages = [];
    for (Map<String, dynamic> jsonPage in jsonPages) {
      pages.add(_jsonToPresentationPage(jsonPage));
    }

    return Presentation(
      id: id,
      podId: podId,
      name: name,
      current: current,
      downloadable: downloadable,
      conversionStatus: conversionStatus,
      pages: pages,
    );
  }

  /// Convert the passed JSON to a conversion status object.
  ConversionStatus _jsonToConversionStatus(Map<String, dynamic> fields) {
    String status = fields["status"];
    bool error = fields["error"];
    bool done = fields["done"];
    int pagesCompleted = fields["pagesCompleted"];
    int numPages = fields["numPages"];

    return ConversionStatus(
      status: status,
      error: error,
      done: done,
      pagesCompleted: pagesCompleted,
      numPages: numPages,
    );
  }

  /// Convert the passed JSON to a presentation page.
  PresentationPage _jsonToPresentationPage(Map<String, dynamic> fields) {
    String pageId = fields["id"];
    int num = fields["num"];
    bool current = fields["current"];
    int xOffset = fields["xOffset"];
    int yOffset = fields["yOffset"];
    int widthRatio = fields["widthRatio"];
    int heightRatio = fields["heightRatio"];

    String thumbUri = fields["thumbUri"];
    String swfUri = fields["swfUri"];
    String txtUri = fields["txtUri"];
    String svgUri = fields["svgUri"];

    return PresentationPage(
      pageId: pageId,
      num: num,
      current: current,
      xOffset: xOffset,
      yOffset: yOffset,
      widthRatio: widthRatio,
      heightRatio: heightRatio,
      thumbUri: thumbUri,
      swfUri: swfUri,
      txtUri: txtUri,
      svgUri: svgUri,
    );
  }
}
