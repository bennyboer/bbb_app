import 'dart:math';

import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/annotation/info/annotation_info.dart';

/// Text annotation info.
class TextInfo implements AnnotationInfo {
  /// Bounds of the text box.
  Rectangle bounds;

  /// Font color
  int fontColor;

  /// Font size.
  double fontSize;

  /// Text to display.
  String text;

  TextInfo({
    this.bounds,
    this.fontColor,
    this.fontSize,
    this.text,
  });
}
