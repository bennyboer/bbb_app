import 'dart:math';

import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/annotation/info/annotation_info.dart';

/// Ellipsis annotation info.
class EllipsisInfo implements AnnotationInfo {
  /// Color of the ellipsis line.
  int color;

  /// Thickness of the ellipsis line.
  double thickness;

  /// Bounds of the ellipsis.
  Rectangle bounds;

  EllipsisInfo({
    this.color,
    this.thickness,
    this.bounds,
  });
}
