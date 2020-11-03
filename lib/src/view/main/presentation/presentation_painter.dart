import 'dart:math';
import 'dart:ui';

import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/annotation/annotation.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/annotation/info/ellipsis.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/annotation/info/line.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/annotation/info/pencil.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/annotation/info/rectangle.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/annotation/info/triangle.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/slide/slide_bounds.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Painter for the presentation.
class PresentationPainter extends CustomPainter {
  /// SVG to draw upon the canvas as base of the presentation slide.
  final DrawableRoot _svg;

  /// Bounds of the slide.
  final SlideBounds _bounds;

  /// Annotations to draw.
  final List<Annotation> _annotations;

  PresentationPainter(
    this._svg,
    this._bounds,
    this._annotations,
  );

  @override
  void paint(Canvas canvas, Size size) {
    _drawSVG(canvas, size);
    _drawAnnotations(canvas, size);

    TextPainter tp = TextPainter(
        text: TextSpan(text: "Hallo Welt", style: TextStyle(fontSize: 40)),
        textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(10, 10));
  }

  /// Draw the SVG on the canvas.
  void _drawSVG(Canvas canvas, Size size) {
    double zoomFactor = size.width / _bounds.viewBoxWidth;

    canvas.scale(zoomFactor, zoomFactor);
    canvas.translate(-_bounds.x, -_bounds.y);

    _svg.draw(canvas, Rect.fromLTWH(0.0, 0.0, size.width, size.height));
  }

  /// Draw the annotations.
  void _drawAnnotations(Canvas canvas, Size size) {
    for (Annotation annotation in _annotations) {
      _drawAnnotation(annotation, canvas, size);
    }
  }

  /// Draw the passed [annotation].
  void _drawAnnotation(Annotation annotation, Canvas canvas, Size size) {
    switch (annotation.annotationType) {
      case "pencil":
        _drawPencilAnnotation(annotation.info as PencilInfo, canvas, size);
        break;
      case "rectangle":
        _drawRectangleAnnotation(
            annotation.info as RectangleInfo, canvas, size);
        break;
      case "triangle":
        _drawTriangleAnnotation(annotation.info as TriangleInfo, canvas, size);
        break;
      case "ellipse":
        _drawEllipsisAnnotation(annotation.info as EllipsisInfo, canvas, size);
        break;
      case "line":
        _drawLineAnnotation(annotation.info as LineInfo, canvas, size);
        break;
    }
  }

  /// Draw a line annotation from the passed [info].
  void _drawLineAnnotation(LineInfo info, Canvas canvas, Size size) {
    double thickness = info.thickness * _bounds.width / 100;

    Paint paint = Paint()
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..color = Color(info.color | 0xFF000000);

    canvas.drawLine(
      Offset(
        info.p1.x * _bounds.width / 100,
        info.p1.y * _bounds.height / 100,
      ),
      Offset(
        info.p2.x * _bounds.width / 100,
        info.p2.y * _bounds.height / 100,
      ),
      paint,
    );
  }

  /// Draw an ellipsis annotation from the passed [info].
  void _drawEllipsisAnnotation(EllipsisInfo info, Canvas canvas, Size size) {
    double thickness = info.thickness * _bounds.width / 100;

    Paint paint = Paint()
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = Color(info.color | 0xFF000000);

    canvas.drawOval(
        Rect.fromLTWH(
          info.bounds.left * _bounds.width / 100,
          info.bounds.top * _bounds.height / 100,
          info.bounds.width * _bounds.width / 100,
          info.bounds.height * _bounds.height / 100,
        ),
        paint);
  }

  /// Draw a triangle annotation from the passed [info].
  void _drawTriangleAnnotation(TriangleInfo info, Canvas canvas, Size size) {
    double thickness = info.thickness * _bounds.width / 100;

    Paint paint = Paint()
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = Color(info.color | 0xFF000000);

    Path path = Path();
    path.moveTo(
      info.p1.x * _bounds.width / 100,
      info.p1.y * _bounds.height / 100,
    );
    path.lineTo(
      info.p2.x * _bounds.width / 100,
      info.p2.y * _bounds.height / 100,
    );
    path.lineTo(
      info.p3.x * _bounds.width / 100,
      info.p3.y * _bounds.height / 100,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  /// Draw a rectangle annotation from the passed [info].
  void _drawRectangleAnnotation(RectangleInfo info, Canvas canvas, Size size) {
    double thickness = info.thickness * _bounds.width / 100;

    Paint paint = Paint()
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = Color(info.color | 0xFF000000);

    canvas.drawRect(
        Rect.fromLTWH(
          info.bounds.left * _bounds.width / 100,
          info.bounds.top * _bounds.height / 100,
          info.bounds.width * _bounds.width / 100,
          info.bounds.height * _bounds.height / 100,
        ),
        paint);
  }

  /// Draw a pencil annotation from the passed [info].
  void _drawPencilAnnotation(PencilInfo info, Canvas canvas, Size size) {
    double thickness = info.thickness * _bounds.width / 100;

    Paint paint = Paint()
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Color(info.color | 0xFF000000);

    Path path = Path();
    if (info.points.isNotEmpty) {
      path.moveTo(
        info.points.first.x * _bounds.width / 100,
        info.points.first.y * _bounds.height / 100,
      );

      for (int i = 1; i < info.points.length; i++) {
        Point point = info.points[i];
        path.lineTo(
          point.x * _bounds.width / 100,
          point.y * _bounds.height / 100,
        );
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
