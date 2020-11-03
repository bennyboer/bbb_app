import 'dart:math';

import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/annotation/info/annotation_info.dart';

/// Rectangle annotation info.
class RectangleInfo implements AnnotationInfo {
  /// Color of the rectangle line.
  int color;

  /// Thickness of the rectangle line.
  double thickness;

  /// Bounds of the rectangle.
  Rectangle bounds;

  RectangleInfo({
    this.color,
    this.thickness,
    this.bounds,
  });
}
