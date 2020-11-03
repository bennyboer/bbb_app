import 'dart:math';

import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/annotation/info/annotation_info.dart';

/// Line annotation info.
class LineInfo implements AnnotationInfo {
  /// Color of the line.
  int color;

  /// Thickness of the line.
  double thickness;

  /// First point of the line.
  Point p1;

  /// Second point of the line.
  Point p2;

  LineInfo({
    this.color,
    this.thickness,
    this.p1,
    this.p2,
  });
}
