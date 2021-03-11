import 'dart:math';

import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/annotation/annotation.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/slide/slide_bounds.dart';

/// Slide of a presentation.
class PresentationSlide {
  /// ID of the slide.
  final String id;

  /// Meeting ID the slide belongs to.
  final String meetingId;

  /// Pod ID.
  final String podId;

  /// Presentation ID the slide belongs to.
  final String presentationId;

  /// Slide number.
  final int num;

  /// Content.
  String content;

  /// Whether the slide is currently shown.
  bool current;

  /// Safe.
  bool safe;

  /// URI to the thumbnail.
  String thumbUri;

  /// Image URI.
  String imageUri;

  /// URI to the SWF.
  String swfUri;

  /// URI to the text representation of the slide.
  String txtUri;

  /// URI to the slides SVG.
  String svgUri;

  /// Bounds of the slide.
  SlideBounds bounds;

  /// Available annotations on the slide.
  Map<String, Annotation> annotations = {};

  /// To hold the cursor position
  Point<double> cursorPos;

  PresentationSlide({
    this.id,
    this.meetingId,
    this.podId,
    this.presentationId,
    this.num,
    this.content,
    this.current,
    this.safe,
    this.thumbUri,
    this.imageUri,
    this.swfUri,
    this.txtUri,
    this.svgUri,
  });
}
