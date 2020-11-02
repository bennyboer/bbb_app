import 'dart:async';

import 'package:bbb_app/src/connect/meeting/main_websocket/module.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/conversion_status.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/presentation_page.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/slide/presentation_slide.dart';

import 'model/presentation.dart';

/// Module providing presentation-related stuff.
class PresentationModule extends Module {
  /// Topic where presentations are published.
  static const String _presentationTopic = "presentations";

  /// Topic where slides are published.
  static const String _slidesTopic = "slides";

  /// Currently loaded presentations by the internal ID (not the presentation ID).
  Map<String, Presentation> _presentationsByID = {};

  /// Currently loaded presentations by the presentation ID.
  Map<String, Presentation> _presentations = {};

  /// Currently loaded presentation slides by the internal ID (not the slide ID).
  Map<String, PresentationSlide> _slidesByID = {};

  /// Currently loaded presentation slides by the slide ID.
  Map<String, PresentationSlide> _slides = {};

  /// Stream controller publishing presentation events.
  StreamController<PresentationEvent> _presentationEventStreamController =
      StreamController.broadcast();

  /// Stream controller publishing slide events.
  StreamController<PresentationSlideEvent> _slideEventStreamController =
      StreamController.broadcast();

  /// Currently shown slide (if any).
  PresentationSlide _currentSlide;

  /// Subscription to slide events.
  StreamSubscription<PresentationSlideEvent> _slideEventSubscription;

  PresentationModule(messageSender) : super(messageSender);

  @override
  void onConnected() {
    subscribe(_presentationTopic);
    subscribe(_slidesTopic);

    _slideEventSubscription = slideEventsStream.listen((event) {
      if (event.slide.current) {
        _currentSlide = event.slide;
      }
    });
  }

  @override
  Future<void> onDisconnect() {
    _slideEventSubscription.cancel();

    _presentationEventStreamController.close();
    _slideEventStreamController.close();
  }

  @override
  void processMessage(Map<String, dynamic> msg) {
    final String method = msg["msg"];

    if (method == "added") {
      String collectionName = msg["collection"];

      _onAdded(collectionName, msg);
    } else if (method == "changed") {
      String collectionName = msg["collection"];

      _onChanged(collectionName, msg);
    }
  }

  /// Get the currently shown slide.
  PresentationSlide get currentSlide => _currentSlide;

  /// Stream of slide events.
  Stream<PresentationSlideEvent> get slideEventsStream =>
      _slideEventStreamController.stream;

  /// Get a presentation by its ID.
  Presentation getPresentation(String id) => _presentations[id];

  /// Stream of presentation events.
  Stream<PresentationEvent> get presentationEventsStream =>
      _presentationEventStreamController.stream;

  /// Called when something should be changed for the given [collectionName].
  void _onChanged(String collectionName, Map<String, dynamic> msg) {
    switch (collectionName) {
      case "presentations":
        _onPresentationChanged(msg);
        break;
      case "slides":
        _onSlideChanged(msg);
        break;
    }
  }

  /// Called when something should be added for the given [collectionName].
  void _onAdded(String collectionName, Map<String, dynamic> msg) {
    switch (collectionName) {
      case "presentations":
        _onPresentationAdded(msg);
        break;
      case "slides":
        _onSlideAdded(msg);
        break;
    }
  }

  /// Called when a presentation should be added.
  void _onPresentationAdded(Map<String, dynamic> msg) {
    String id = msg["id"];

    Map<String, dynamic> fields = msg["fields"];

    Presentation presentation = _jsonToPresentation(fields);

    _presentationsByID[id] = presentation;
    _presentations[presentation.id] = presentation;

    _presentationEventStreamController
        .add(PresentationEvent(EventType.ADDED, presentation));
  }

  /// Called when a presentation should be changed.
  void _onPresentationChanged(Map<String, dynamic> msg) {
    String id = msg["id"];
    Map<String, dynamic> fields = msg["fields"];

    Presentation presentation = _presentationsByID[id];

    if (fields.containsKey("current")) presentation.current = fields["current"];
    if (fields.containsKey("downloadable"))
      presentation.downloadable = fields["downloadable"];
    if (fields.containsKey("conversion"))
      presentation.conversionStatus =
          _jsonToConversionStatus(fields["conversion"]);
    if (fields.containsKey("pages")) {
      presentation.pages.clear();

      for (Map<String, dynamic> pageJson in fields["pages"]) {
        presentation.pages.add(_jsonToPresentationPage(pageJson));
      }
    }

    _presentationEventStreamController
        .add(PresentationEvent(EventType.CHANGED, presentation));
  }

  /// Called when a slide should be added.
  void _onSlideAdded(Map<String, dynamic> msg) {
    String id = msg["id"];

    Map<String, dynamic> fields = msg["fields"];
    PresentationSlide slide = _jsonToPresentationSlide(fields);

    _slidesByID[id] = slide;
    _slides[slide.id] = slide;

    _slideEventStreamController
        .add(PresentationSlideEvent(EventType.ADDED, slide));
  }

  /// Called when a slide should be changed.
  void _onSlideChanged(Map<String, dynamic> msg) {
    String id = msg["id"];

    PresentationSlide slide = _slidesByID[id];

    Map<String, dynamic> fields = msg["fields"];
    if (fields.containsKey("current")) slide.current = fields["current"];

    _slideEventStreamController
        .add(PresentationSlideEvent(EventType.CHANGED, slide));
  }

  /// Convert the passed JSON to a presentation slide.
  PresentationSlide _jsonToPresentationSlide(Map<String, dynamic> fields) {
    String id = fields["id"];
    String meetingId = fields["meetingId"];
    String podId = fields["posId"];
    String presentationId = fields["presentationId"];

    int num = fields["num"];
    bool current = fields["current"];
    String content = fields["content"];
    bool safe = fields["safe"];

    String imageUri = fields["imageUri"];
    String thumbUri = fields["thumbUri"];
    String swfUri = fields["swfUri"];
    String txtUri = fields["txtUri"];
    String svgUri = fields["svgUri"];

    return PresentationSlide(
      id: id,
      meetingId: meetingId,
      podId: podId,
      presentationId: presentationId,
      num: num,
      current: current,
      content: content,
      safe: safe,
      imageUri: imageUri,
      thumbUri: thumbUri,
      swfUri: swfUri,
      txtUri: txtUri,
      svgUri: svgUri,
    );
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

/// Event published by the presentation stream controller.
class PresentationEvent {
  final EventType eventType;
  final Presentation presentation;

  PresentationEvent(this.eventType, this.presentation);
}

/// Event published by the presentation slide stream controller.
class PresentationSlideEvent {
  final EventType eventType;
  final PresentationSlide slide;

  PresentationSlideEvent(this.eventType, this.slide);
}

/// Available event types.
enum EventType {
  ADDED,
  CHANGED,
  REMOVED,
}
