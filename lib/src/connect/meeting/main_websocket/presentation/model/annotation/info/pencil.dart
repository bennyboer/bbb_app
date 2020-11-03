import 'dart:math';

import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/annotation/info/annotation_info.dart';

/// Pencil annotation info.
class PencilInfo implements AnnotationInfo {
  /// Color of the pencil line.
  int color;

  /// Thickness of the pencil line.
  double thickness;

  /// Points of the pencil line.
  List<Point> points;

  PencilInfo({
    this.color,
    this.thickness,
    this.points,
  });
}
