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

  /// Commands describing how the [points] list
  /// is to be consumed.
  /// They are only present, when the status of the annotation is DRAW_END,
  /// otherwise this list is null.
  /// So if this list is null, we need consider the points list to contain data for
  /// an unsmoothed line. If this list isn't null we need to process it using this
  /// commands list.
  List<PencilCommand> commands;

  PencilInfo({
    this.color,
    this.thickness,
    this.points,
    this.commands,
  });
}

/// Command of a pencil movement.
enum PencilCommand {
  /// Simple move to command -> consume 1 point in the points list.
  MOVE_TO,

  /// Simple line to command -> consume 1 point in the points list.
  LINE_TO,

  /// Do a quadratic curve -> consume 2 points in the points list.
  /// First point is the control point, second is the coordinate.
  QUADRATIC_CURVE_TO,

  /// Do a cubic curve -> consumes 3 points in the points list.
  /// First and second points are control points, third is the coordinate.
  CUBIC_CURVE_TO,
}
