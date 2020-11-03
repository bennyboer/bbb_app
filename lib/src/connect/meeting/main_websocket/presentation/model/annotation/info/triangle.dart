import 'dart:math';

import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/annotation/info/annotation_info.dart';

/// Triangle annotation info.
class TriangleInfo implements AnnotationInfo {
  /// Color of the triangle line.
  int color;

  /// Thickness of the triangle line.
  double thickness;

  /// First point of the triangle.
  Point p1;

  /// Second point of the triangle.
  Point p2;

  /// Third point of the triangle.
  Point p3;

  TriangleInfo({
    this.color,
    this.thickness,
    this.p1,
    this.p2,
    this.p3,
  });
}
