import 'dart:async';
import 'dart:math';

import 'package:bbb_app/src/connect/meeting/main_websocket/module.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/annotation/annotation.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/annotation/info/annotation_info.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/annotation/info/ellipsis.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/annotation/info/line.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/annotation/info/pencil.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/annotation/info/poll_result.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/conversion_status.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/presentation_page.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/slide/presentation_slide.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/slide/slide_bounds.dart';
import 'package:bbb_app/src/connect/meeting/meeting_info.dart';

import 'model/annotation/info/rectangle.dart';
import 'model/annotation/info/text.dart';
import 'model/annotation/info/triangle.dart';
import 'model/presentation.dart';

/// Module providing presentation-related stuff.
class PresentationModule extends Module {
  /// Topic where presentations are published.
  static const String _presentationTopic = "presentations";

  /// Topic where slides are published.
  static const String _slidesTopic = "slides";

  /// Topic where slide positions are published.
  static const String _slidePositionTopic = "slide-positions";

  /// Topic where annotations are published.
  static const String _annotationsTopic = "annotations";

  /// Info for the current meeting.
  final MeetingInfo _meetingInfo;

  /// Topic where stream annotations (painting on the slides) are published over.
  final String _streamAnnotationsTopic;

  /// Currently loaded presentations by the internal ID (not the presentation ID).
  Map<String, Presentation> _presentationsByID = {};

  /// Currently loaded presentations by the presentation ID.
  Map<String, Presentation> _presentations = {};

  /// Currently loaded presentation slides by the internal ID (not the slide ID).
  Map<String, PresentationSlide> _slidesByID = {};

  /// Currently loaded presentation slides by the slide ID.
  Map<String, PresentationSlide> _slides = {};

  /// Mapping from slide position IDs to slide IDs.
  Map<String, String> _slidePositionIDsToSlideIDs = {};

  /// Slide bounds that have been added before the actual slide is there.
  Map<String, SlideBounds> _tmpSlideBounds = {};

  /// Stream controller publishing presentation events.
  StreamController<PresentationEvent> _presentationEventStreamController =
      StreamController.broadcast();

  /// Stream controller publishing slide events.
  StreamController<PresentationSlideEvent> _slideEventStreamController =
      StreamController.broadcast();

  /// Currently shown slide (if any).
  PresentationSlide _currentSlide;

  /// Currently shown presentation (if any).
  Presentation _currentPresentation;

  /// The last received poll result annotation.
  Annotation _lastPollResultAnnotation;

  /// Subscription to slide events.
  StreamSubscription<PresentationSlideEvent> _slideEventSubscription;

  /// Subscription to presentation events.
  StreamSubscription<PresentationEvent> _presentationEventSubscription;

  /// Topic where stream-cursor messages are published.
  final String _streamCursorTopic;

  PresentationModule(messageSender, this._meetingInfo)
      : _streamAnnotationsTopic =
            "stream-annotations-${_meetingInfo.meetingID}",
        _streamCursorTopic = "stream-cursor-${_meetingInfo.meetingID}",
        super(messageSender);

  @override
  void onConnected() {
    subscribe(_presentationTopic);
    subscribe(_slidesTopic);
    subscribe(_slidePositionTopic);
    subscribe(_annotationsTopic);
    subscribe(_streamAnnotationsTopic, params: [
      "added",
      {
        "useCollection": false,
        "args": [],
      },
    ]);
    subscribe(_streamAnnotationsTopic, params: [
      "removed",
      {
        "useCollection": false,
        "args": [],
      },
    ]);
    subscribe(_streamCursorTopic, params: [
      "message",
      {
        "useCollection": false,
        "args": [],
      },
    ]);

    _presentationEventSubscription = presentationEventsStream.listen((event) {
      if ((event.eventType == EventType.ADDED ||
              event.eventType == EventType.CHANGED) &&
          event.presentation.current) {
        _currentPresentation = event.presentation;
      }
    });

    _slideEventSubscription = slideEventsStream.listen((event) {
      if ((event.eventType == SlideEventType.ADDED ||
              event.eventType == SlideEventType.CHANGED) &&
          event.slide.current) {
        _currentSlide = event.slide;
      }
    });
  }

  @override
  Future<void> onDisconnect() async {
    _slideEventSubscription.cancel();
    _presentationEventSubscription.cancel();

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

  /// Get the currently shown presentation.
  Presentation get currentPresentation => _currentPresentation;

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
    if (collectionName == _streamAnnotationsTopic) {
      _onStreamAnnotationChanged(msg);
    }
    if (collectionName == _streamCursorTopic) {
      _onStreamCursorChanged(msg);
    }

    switch (collectionName) {
      case "presentations":
        _onPresentationChanged(msg);
        break;
      case "slides":
        _onSlideChanged(msg);
        break;
      case "slide-positions":
        _onSlidePositionChanged(msg);
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
      case "slide-positions":
        _onSlidePositionAdded(msg);
        break;
      case "annotations":
        _onAnnotationsAdded(msg);
        break;
    }
  }

  /// Called when annotations should be added.
  void _onAnnotationsAdded(Map<String, dynamic> msg) {
    Map<String, dynamic> fields = msg["fields"];
    String annotationId = fields["id"];
    String slideId = fields["whiteboardId"];

    Map<String, dynamic> annotationJson = {
      "whiteboardId": slideId,
      "userId": fields["userId"],
      "annotation": fields,
    };
    PresentationSlide slide = _slides[slideId];
    Annotation annotation = _jsonToAnnotation(annotationJson);
    slide.annotations[annotationId] = annotation;

    if (annotation.info is PollResult) {
      if (_lastPollResultAnnotation != null) {
        // Only allow one poll result shown.
        slide.annotations.remove(_lastPollResultAnnotation.annotationId);
      }

      _lastPollResultAnnotation = annotation;
    }

    _slideEventStreamController.add(
        PresentationSlideEvent(SlideEventType.ANNOTATIONS_ONLY_CHANGED, slide));
  }

  /// Reads x and yPercent from cursor-stream and adds it to _currentSlide
  void _onStreamCursorChanged(Map<String, dynamic> msg) {
    Map<String, dynamic> fields = msg["fields"];
    List<dynamic> argsJson = fields["args"];
    Map<String, dynamic> argJson = argsJson[0];
    Map<String, dynamic> cursorsJson = argJson["cursors"];
    String cursorId = cursorsJson.keys.elementAt(0);

    _currentSlide.cursorPos = Point(
        cursorsJson[cursorId]["xPercent"], cursorsJson[cursorId]["yPercent"]);
    _slideEventStreamController.add(PresentationSlideEvent(
        SlideEventType.ANNOTATIONS_ONLY_CHANGED, _currentSlide));
  }

  /// Called when a stream annotation (paint) should be changed.
  void _onStreamAnnotationChanged(Map<String, dynamic> msg) {
    Map<String, dynamic> fields = msg["fields"];

    String eventName = fields["eventName"];
    if (eventName == "added") {
      bool shouldPublishEvent = false;
      PresentationSlide slideChanged;

      List<dynamic> argsJson = fields["args"];
      for (Map<String, dynamic> argJson in argsJson) {
        List<dynamic> annotationsJson = argJson["annotations"];
        for (Map<String, dynamic> annotationJson in annotationsJson) {
          String annotationId = annotationJson["annotation"]["id"];
          String slideId = annotationJson["whiteboardId"];

          PresentationSlide slide = _slides[slideId];
          if (slide.annotations.containsKey(annotationId)) {
            Annotation annotation = _jsonToAnnotation(
                annotationJson, slide.annotations[annotationId]);
            slide.annotations[annotationId] = annotation;

            if (annotation.status == "DRAW_END") {
              shouldPublishEvent = true; // Only send update when really needed
            }

            if (annotation.info is PollResult) {
              if (_lastPollResultAnnotation != null) {
                // Only allow one poll result shown.
                slide.annotations
                    .remove(_lastPollResultAnnotation.annotationId);
              }

              _lastPollResultAnnotation = annotation;
            }
          } else {
            slide.annotations[annotationId] = _jsonToAnnotation(annotationJson);
            shouldPublishEvent = true;
          }

          slideChanged = slide;
        }
      }

      if (shouldPublishEvent) {
        _slideEventStreamController.add(PresentationSlideEvent(
            SlideEventType.ANNOTATIONS_ONLY_CHANGED, slideChanged));
      }
    } else if (eventName == "removed") {
      PresentationSlide slideChanged;

      List<dynamic> argsJson = fields["args"];
      for (Map<String, dynamic> argJson in argsJson) {
        String slideId = argJson["whiteboardId"];
        PresentationSlide slide = _slides[slideId];

        if (argJson.containsKey("shapeId")) {
          String annotationId = argJson["shapeId"];
          slide.annotations.remove(annotationId);
        } else {
          slide.annotations.clear();
        }

        slideChanged = slide;
      }

      _slideEventStreamController.add(PresentationSlideEvent(
          SlideEventType.ANNOTATIONS_ONLY_CHANGED, slideChanged));
    }
  }

  /// Convert the passed JSON map to an annotation.
  /// A optional existing annotation is filled to be updated.
  Annotation _jsonToAnnotation(Map<String, dynamic> fields,
      [Annotation existing]) {
    String whiteboardId = fields["whiteboardId"];
    String userId = fields["userId"];

    Map<String, dynamic> annotationJson = fields["annotation"];
    String annotationId = annotationJson["id"];
    String status = annotationJson["status"];
    int position = annotationJson["position"];
    String annotationType = annotationJson["annotationType"];

    if (existing != null) {
      existing.status = status;
      existing.annotationType = annotationType;
      existing.info = _jsonToAnnotationInfo(
          annotationType, annotationJson["annotationInfo"], existing.info);

      return existing;
    } else {
      return Annotation(
        whiteboardId: whiteboardId,
        userId: userId,
        annotationId: annotationId,
        status: status,
        position: position,
        annotationType: annotationType,
        info: _jsonToAnnotationInfo(
            annotationType, annotationJson["annotationInfo"]),
      );
    }
  }

  /// Convert the passed JSON map to a annotation info for the given [type].
  /// An optional already existing annotation info is filled to be updated.
  AnnotationInfo _jsonToAnnotationInfo(
    String type,
    Map<String, dynamic> fields, [
    AnnotationInfo existing,
  ]) {
    switch (type) {
      case "pencil":
        return _jsonToPencilInfo(fields, existing as PencilInfo);
      case "rectangle":
        return _jsonToRectangleInfo(fields, existing as RectangleInfo);
      case "triangle":
        return _jsonToTriangleInfo(fields, existing as TriangleInfo);
      case "ellipse":
        return _jsonToEllipsisInfo(fields, existing as EllipsisInfo);
      case "line":
        return _jsonToLineInfo(fields, existing as LineInfo);
      case "text":
        return _jsonToTextInfo(fields, existing as TextInfo);
      case "poll_result":
        return _jsonToPollResult(fields, existing as PollResult);
    }

    throw Exception("Annotation info type '$type' unknown");
  }

  /// Convert the passed JSON map to a poll result representation.
  /// An existing info is passed (when it exists) to be filled.
  PollResult _jsonToPollResult(Map<String, dynamic> fields,
      [PollResult existing]) {
    int responders = fields["numResponders"];
    int respondents = fields["numRespondents"];

    List<dynamic> points = fields["points"];
    double x = points[0].toDouble();
    double y = points[1].toDouble();
    double width = points[2].toDouble();
    double height = points[3].toDouble();
    Rectangle bounds = Rectangle(x, y, width, height);

    List<dynamic> resultsJson = fields["result"];
    List<PollResultEntry> entries = [];
    for (Map<String, dynamic> resultEntryJson in resultsJson) {
      int id = resultEntryJson["id"];
      String key = resultEntryJson["key"];
      int votes = resultEntryJson["numVotes"];

      entries.add(PollResultEntry(
        id: id,
        key: key,
        votes: votes,
      ));
    }

    if (existing != null) {
      existing.responders = responders;
      existing.respondents = respondents;
      existing.bounds = bounds;
      existing.entries = entries;

      return existing;
    } else {
      return PollResult(
        responders: responders,
        respondents: respondents,
        bounds: bounds,
        entries: entries,
      );
    }
  }

  /// Convert the passed JSON map to a text annotation info representation.
  /// An existing info is passed (when it exists) to be filled.
  TextInfo _jsonToTextInfo(Map<String, dynamic> fields, [TextInfo existing]) {
    int fontColor = fields["fontColor"];
    double fontSize = fields["calcedFontSize"].toDouble();

    double x = fields["x"].toDouble();
    double y = fields["y"].toDouble();
    double width = fields["textBoxWidth"].toDouble();
    double height = fields["textBoxHeight"].toDouble();

    String text = fields["text"];

    Rectangle bounds = Rectangle(x, y, width, height);

    if (existing != null) {
      existing.text = text;
      existing.bounds = bounds;
      existing.fontColor = fontColor;
      existing.fontSize = fontSize;

      return existing;
    } else {
      return TextInfo(
        text: text,
        bounds: bounds,
        fontColor: fontColor,
        fontSize: fontSize,
      );
    }
  }

  /// Convert the passed JSON map to a line annotation info representation.
  /// An existing info is passed (when it exists) to be filled.
  LineInfo _jsonToLineInfo(Map<String, dynamic> fields, [LineInfo existing]) {
    int color = fields["color"];
    double thickness = fields["thickness"].toDouble();

    List<dynamic> pointsJson = fields["points"];
    List<Point> points = [];
    for (int i = 0; i < pointsJson.length; i += 2) {
      points.add(Point(
        pointsJson[i].toDouble(),
        pointsJson[i + 1].toDouble(),
      ));
    }

    if (existing != null) {
      existing.color = color;
      existing.thickness = thickness;
      existing.p1 = points.first;
      existing.p2 = points.last;

      return existing;
    } else {
      return LineInfo(
        color: color,
        thickness: thickness,
        p1: points.first,
        p2: points.last,
      );
    }
  }

  /// Convert the passed JSON map to a ellipsis annotation info representation.
  /// An existing info is passed (when it exists) to be filled.
  EllipsisInfo _jsonToEllipsisInfo(Map<String, dynamic> fields,
      [EllipsisInfo existing]) {
    int color = fields["color"];
    double thickness = fields["thickness"].toDouble();

    List<dynamic> pointsJson = fields["points"];
    List<Point> points = [];
    for (int i = 0; i < pointsJson.length; i += 2) {
      points.add(Point(
        pointsJson[i].toDouble(),
        pointsJson[i + 1].toDouble(),
      ));
    }
    Rectangle bounds = Rectangle.fromPoints(points.first, points.last);

    if (existing != null) {
      existing.color = color;
      existing.thickness = thickness;
      existing.bounds = bounds;

      return existing;
    } else {
      return EllipsisInfo(
        color: color,
        thickness: thickness,
        bounds: bounds,
      );
    }
  }

  /// Convert the passed JSON map to a triangle annotation info representation.
  /// An existing info is passed (when it exists) to be filled.
  TriangleInfo _jsonToTriangleInfo(Map<String, dynamic> fields,
      [TriangleInfo existing]) {
    int color = fields["color"];
    double thickness = fields["thickness"].toDouble();

    List<dynamic> pointsJson = fields["points"];
    List<Point> points = [];
    for (int i = 0; i < pointsJson.length; i += 2) {
      points.add(Point(
        pointsJson[i].toDouble(),
        pointsJson[i + 1].toDouble(),
      ));
    }

    // There are only two points send forming a rectangle to display a triangle in.
    // We are calculating the correct points here.
    Point p1 = Point(
        points.first.x + (points.last.x - points.first.x) / 2, points.first.y);
    Point p2 = Point(points.first.x, points.last.y);
    Point p3 = Point(points.last.x, points.last.y);

    if (existing != null) {
      existing.color = color;
      existing.thickness = thickness;
      existing.p1 = p1;
      existing.p2 = p2;
      existing.p3 = p3;

      return existing;
    } else {
      return TriangleInfo(
        color: color,
        thickness: thickness,
        p1: p1,
        p2: p2,
        p3: p3,
      );
    }
  }

  /// Convert the passed JSON map to a rectangle annotation info representation.
  /// An existing info is passed (when it exists) to be filled.
  RectangleInfo _jsonToRectangleInfo(Map<String, dynamic> fields,
      [RectangleInfo existing]) {
    int color = fields["color"];
    double thickness = fields["thickness"].toDouble();

    List<dynamic> pointsJson = fields["points"];
    List<Point> points = [];
    for (int i = 0; i < pointsJson.length; i += 2) {
      points.add(Point(
        pointsJson[i].toDouble(),
        pointsJson[i + 1].toDouble(),
      ));
    }
    Rectangle bounds = Rectangle.fromPoints(points.first, points.last);

    if (existing != null) {
      existing.color = color;
      existing.thickness = thickness;
      existing.bounds = bounds;

      return existing;
    } else {
      return RectangleInfo(
        color: color,
        thickness: thickness,
        bounds: bounds,
      );
    }
  }

  /// Convert the passed JSON map to a pencil annotation info representation.
  /// An existing pencil info is passed (when it exists) to be filled.
  PencilInfo _jsonToPencilInfo(Map<String, dynamic> fields,
      [PencilInfo existing]) {
    int color = fields["color"];
    double thickness = fields["thickness"].toDouble();

    List<dynamic> pointsJson = fields["points"];
    List<Point> points = [];
    for (int i = 0; i < pointsJson.length; i += 2) {
      points.add(Point(
        pointsJson[i].toDouble(),
        pointsJson[i + 1].toDouble(),
      ));
    }

    List<PencilCommand> commands;
    if (fields.containsKey("commands")) {
      List<dynamic> jsonCommands = fields["commands"];
      commands = [];
      for (var jsonCommand in jsonCommands) {
        commands.add(_mapPencilCommandFromNum(jsonCommand));
      }
    }

    if (existing != null) {
      existing.color = color;
      existing.thickness = thickness;
      existing.points = points;
      existing.commands = commands;

      return existing;
    } else {
      return PencilInfo(
        color: color,
        thickness: thickness,
        points: points,
        commands: commands,
      );
    }
  }

  /// Map the passed raw pencil command number to the enum representation.
  PencilCommand _mapPencilCommandFromNum(int num) {
    switch (num) {
      case 1:
        return PencilCommand.MOVE_TO;
      case 2:
        return PencilCommand.LINE_TO;
      case 3:
        return PencilCommand.QUADRATIC_CURVE_TO;
      case 4:
        return PencilCommand.CUBIC_CURVE_TO;
      default:
        throw new Exception("Pencil command with number $num unknown");
    }
  }

  /// Called when a slide position should be added.
  void _onSlidePositionAdded(Map<String, dynamic> msg) {
    String id = msg["id"];

    Map<String, dynamic> fields = msg["fields"];

    SlideBounds bounds = _jsonToSlideBounds(fields);

    String slideId = fields["id"];
    _slidePositionIDsToSlideIDs[id] = slideId;

    PresentationSlide slide = _slides[slideId];
    if (slide != null) {
      slide.bounds = bounds;

      _slideEventStreamController
          .add(PresentationSlideEvent(SlideEventType.CHANGED, slide));
    } else {
      // Slide not yet there -> cache temporarily until slide is there
      _tmpSlideBounds[slideId] = bounds;
    }
  }

  /// Called when a slide position should be changed.
  void _onSlidePositionChanged(Map<String, dynamic> msg) {
    String id = msg["id"];
    String slideId = _slidePositionIDsToSlideIDs[id];
    PresentationSlide slide = _slides[slideId];

    SlideBounds bounds;
    if (slide == null) {
      // Check if slide bounds are already there
      if (_tmpSlideBounds.containsKey(slideId)) {
        bounds = _tmpSlideBounds[slideId];
      }
    } else {
      bounds = slide.bounds;
    }

    Map<String, dynamic> fields = msg["fields"];

    if (fields.containsKey("x")) bounds.x = fields["x"].toDouble();
    if (fields.containsKey("y")) bounds.y = fields["y"].toDouble();
    if (fields.containsKey("viewBoxWidth"))
      bounds.viewBoxWidth = fields["viewBoxWidth"].toDouble();
    if (fields.containsKey("viewBoxHeight"))
      bounds.viewBoxHeight = fields["viewBoxHeight"].toDouble();

    if (slide != null) {
      _slideEventStreamController
          .add(PresentationSlideEvent(SlideEventType.CHANGED, slide));
    }
  }

  /// Convert the passed JSON to slide bounds.
  SlideBounds _jsonToSlideBounds(Map<String, dynamic> fields) {
    double width = fields["width"].toDouble();
    double height = fields["height"].toDouble();
    double x = fields["x"].toDouble();
    double y = fields["y"].toDouble();
    double viewBoxWidth = fields["viewBoxWidth"].toDouble();
    double viewBoxHeight = fields["viewBoxHeight"].toDouble();

    return SlideBounds(
      width: width,
      height: height,
      x: x,
      y: y,
      viewBoxWidth: viewBoxWidth,
      viewBoxHeight: viewBoxHeight,
    );
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

    // Check if slide bounds are already there
    if (_tmpSlideBounds.containsKey(slide.id)) {
      slide.bounds = _tmpSlideBounds.remove(slide.id);
    }

    _slideEventStreamController
        .add(PresentationSlideEvent(SlideEventType.ADDED, slide));
  }

  /// Called when a slide should be changed.
  void _onSlideChanged(Map<String, dynamic> msg) {
    String id = msg["id"];

    PresentationSlide slide = _slidesByID[id];

    Map<String, dynamic> fields = msg["fields"];
    if (fields.containsKey("current")) slide.current = fields["current"];

    _slideEventStreamController
        .add(PresentationSlideEvent(SlideEventType.CHANGED, slide));
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
    bool current = fields["current"] ?? false;
    bool downloadable = fields["downloadable"];

    Map<String, dynamic> conversion = fields["conversion"];
    ConversionStatus conversionStatus = _jsonToConversionStatus(conversion);

    List<PresentationPage> pages = [];
    if (fields.containsKey("pages")) {
      List<dynamic> jsonPages = fields["pages"];
      for (Map<String, dynamic> jsonPage in jsonPages) {
        pages.add(_jsonToPresentationPage(jsonPage));
      }
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
  final SlideEventType eventType;
  final PresentationSlide slide;

  PresentationSlideEvent(this.eventType, this.slide);
}

/// Available event types.
enum EventType {
  ADDED,
  CHANGED,
  REMOVED,
}

/// Available event types.
enum SlideEventType {
  ADDED,
  CHANGED,

  /// Whether only the annotations changed
  ANNOTATIONS_ONLY_CHANGED,
  REMOVED,
}
