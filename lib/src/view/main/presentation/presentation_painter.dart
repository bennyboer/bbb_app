import 'dart:math';
import 'dart:ui';

import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/annotation/annotation.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/annotation/info/ellipsis.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/annotation/info/line.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/annotation/info/pencil.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/annotation/info/poll_result.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/annotation/info/rectangle.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/annotation/info/text.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/annotation/info/triangle.dart';
import 'package:bbb_app/src/view/main/presentation/presentation_painter_controller.dart';
import 'package:flutter/material.dart';

/// Painter for the presentation.
class PresentationPainter extends CustomPainter {
  /// Controller for the painter.
  final PresentationPainterController controller;

  PresentationPainter(this.controller) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    if (controller.bounds == null) {
      return;
    }

    double zoomFactor = size.width / controller.bounds.viewBoxWidth;

    canvas.scale(zoomFactor, zoomFactor);
    canvas.translate(-controller.bounds.x, -controller.bounds.y);

    _drawAnnotations(canvas, size);
    _drawCursor(canvas, size);
  }

  void _drawCursor(Canvas canvas, Size size) {
    if (controller.cursorPos == null) {
      return;
    }

    double thickness = 10; //info.thickness * controller.bounds.width / 100;

    Paint paint = Paint()
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = Color(70 | 0xFFF00000);

    //canvas.drawOval(Rect.fromLTWH(controller.cursorPos.x,controller.cursorPos.y,3,3),paint);

    canvas.drawOval(
        Rect.fromLTWH(
          controller.cursorPos.x * controller.bounds.width / 100,
          controller.cursorPos.y * controller.bounds.height / 100,
          3, // * controller.bounds.width / 100,
          3, // * controller.bounds.height / 100,
        ),
        paint);
  }

  /// Draw the annotations.
  void _drawAnnotations(Canvas canvas, Size size) {
    if (controller.annotations == null) {
      return;
    }

    for (Annotation annotation in controller.annotations) {
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
      case "text":
        _drawTextAnnotation(annotation.info as TextInfo, canvas, size);
        break;
      case "poll_result":
        _drawPollResult(annotation.info as PollResult, canvas, size);
        break;
    }
  }

  /// Draw a poll result from the passed [info].
  void _drawPollResult(PollResult info, Canvas canvas, Size size) {
    double marginBottomRight = controller.bounds.width / 100;

    double x = info.bounds.left * controller.bounds.width / 100;
    double y = info.bounds.top * controller.bounds.height / 100;
    double width =
        info.bounds.width * controller.bounds.width / 100 - marginBottomRight;
    double height =
        info.bounds.height * controller.bounds.height / 100 - marginBottomRight;

    double entryHeight = height / info.entries.length;

    // Draw box around poll result
    Paint paint = Paint()
      ..strokeWidth = controller.bounds.width / 500
      ..color = Color(0xFF778899);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, width, height),
        Radius.circular(controller.bounds.width / 200),
      ),
      paint,
    );

    // Find widest entry key string
    List<TextPainter> painters = [];
    double maxEntryKeyWidth = 0.0;
    for (PollResultEntry entry in info.entries) {
      TextPainter tp = TextPainter(
        text: TextSpan(
          text: entry.key,
          style: TextStyle(
            fontSize: entryHeight * 0.75,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();

      maxEntryKeyWidth = max(tp.width, maxEntryKeyWidth);

      painters.add(tp);
    }

    // Draw poll result entries
    double curY = y;
    for (int i = 0; i < info.entries.length; i++) {
      PollResultEntry entry = info.entries[i];
      TextPainter painter = painters[i];

      _drawPollResultEntry(
        entry,
        info.responders,
        painter,
        maxEntryKeyWidth,
        Rect.fromLTWH(x, curY, width, entryHeight),
        canvas,
        size,
      );

      curY += entryHeight;
    }
  }

  /// Draw the passed poll result [entry] at the given [rect].
  void _drawPollResultEntry(
    PollResultEntry entry,
    int responders,
    TextPainter keyPainter,
    double maxEntryKeyWidth,
    Rect rect,
    Canvas canvas,
    Size size,
  ) {
    final double padding = controller.bounds.width / 200;
    double x = rect.left + padding;

    // Draw entry key
    keyPainter.paint(
        canvas, Offset(x, rect.top + (rect.height - keyPainter.height) / 2));

    x += maxEntryKeyWidth + padding;

    double widthFactor = entry.votes / responders;
    Paint barPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    double maxBarWidth = rect.width - (x - rect.left) - padding;
    Rect barRect = Rect.fromLTWH(
      x,
      rect.top + padding / 2,
      max(
        maxBarWidth * widthFactor,
        controller.bounds.width / 500,
      ),
      rect.height - padding,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        barRect,
        Radius.circular(padding),
      ),
      barPaint,
    );

    // Draw label on bar
    TextPainter tp = TextPainter(
      text: TextSpan(
        text: "${(widthFactor * 100).round()}% (${entry.votes})",
        style: TextStyle(
          color: Colors.black87,
          fontSize: keyPainter.text.style.fontSize * 0.75,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();

    tp.paint(
      canvas,
      Offset(
        barRect.left + (maxBarWidth - tp.width) / 2,
        barRect.top + (barRect.height - tp.height) / 2,
      ),
    );
  }

  /// Draw a text annotation from the passed [info].
  void _drawTextAnnotation(TextInfo info, Canvas canvas, Size size) {
    TextPainter tp = TextPainter(
      text: TextSpan(
        text: info.text,
        style: TextStyle(
          fontSize: info.fontSize * controller.bounds.height / 100,
          color: Color(info.fontColor | 0xFF000000),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout(maxWidth: info.bounds.width * controller.bounds.width / 100);

    tp.paint(
        canvas,
        Offset(info.bounds.left * controller.bounds.width / 100,
            info.bounds.top * controller.bounds.height / 100));
  }

  /// Draw a line annotation from the passed [info].
  void _drawLineAnnotation(LineInfo info, Canvas canvas, Size size) {
    double thickness = info.thickness * controller.bounds.width / 100;

    Paint paint = Paint()
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..color = Color(info.color | 0xFF000000);

    canvas.drawLine(
      Offset(
        info.p1.x * controller.bounds.width / 100,
        info.p1.y * controller.bounds.height / 100,
      ),
      Offset(
        info.p2.x * controller.bounds.width / 100,
        info.p2.y * controller.bounds.height / 100,
      ),
      paint,
    );
  }

  /// Draw an ellipsis annotation from the passed [info].
  void _drawEllipsisAnnotation(EllipsisInfo info, Canvas canvas, Size size) {
    double thickness = info.thickness * controller.bounds.width / 100;

    Paint paint = Paint()
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = Color(info.color | 0xFF000000);

    canvas.drawOval(
        Rect.fromLTWH(
          info.bounds.left * controller.bounds.width / 100,
          info.bounds.top * controller.bounds.height / 100,
          info.bounds.width * controller.bounds.width / 100,
          info.bounds.height * controller.bounds.height / 100,
        ),
        paint);
  }

  /// Draw a triangle annotation from the passed [info].
  void _drawTriangleAnnotation(TriangleInfo info, Canvas canvas, Size size) {
    double thickness = info.thickness * controller.bounds.width / 100;

    Paint paint = Paint()
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = Color(info.color | 0xFF000000);

    Path path = Path();
    path.moveTo(
      info.p1.x * controller.bounds.width / 100,
      info.p1.y * controller.bounds.height / 100,
    );
    path.lineTo(
      info.p2.x * controller.bounds.width / 100,
      info.p2.y * controller.bounds.height / 100,
    );
    path.lineTo(
      info.p3.x * controller.bounds.width / 100,
      info.p3.y * controller.bounds.height / 100,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  /// Draw a rectangle annotation from the passed [info].
  void _drawRectangleAnnotation(RectangleInfo info, Canvas canvas, Size size) {
    double thickness = info.thickness * controller.bounds.width / 100;

    Paint paint = Paint()
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = Color(info.color | 0xFF000000);

    canvas.drawRect(
        Rect.fromLTWH(
          info.bounds.left * controller.bounds.width / 100,
          info.bounds.top * controller.bounds.height / 100,
          info.bounds.width * controller.bounds.width / 100,
          info.bounds.height * controller.bounds.height / 100,
        ),
        paint);
  }

  /// Draw a pencil annotation from the passed [info].
  void _drawPencilAnnotation(PencilInfo info, Canvas canvas, Size size) {
    double thickness = info.thickness * controller.bounds.width / 100;

    Paint paint = Paint()
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Color(info.color | 0xFF000000);

    if (info.commands == null) {
      _drawUnsmoothedPencilAnnotation(info, canvas, size, thickness, paint);
    } else {
      _drawSmoothedPencilAnnotation(info, canvas, size, thickness, paint);
    }
  }

  /// Draw an unsmoothed pencil annotation.
  /// This one will be present, when the user has not finished drawing
  /// the pencil line and thus will be unsmoothed.
  void _drawUnsmoothedPencilAnnotation(
    PencilInfo info,
    Canvas canvas,
    Size size,
    double thickness,
    Paint paint,
  ) {
    Path path = Path();
    if (info.points.isNotEmpty) {
      path.moveTo(
        info.points.first.x * controller.bounds.width / 100,
        info.points.first.y * controller.bounds.height / 100,
      );

      for (int i = 1; i < info.points.length; i++) {
        Point point = info.points[i];
        path.lineTo(
          point.x * controller.bounds.width / 100,
          point.y * controller.bounds.height / 100,
        );
      }
    }

    canvas.drawPath(path, paint);
  }

  /// Draw a smoothed pencil annotation.
  void _drawSmoothedPencilAnnotation(
    PencilInfo info,
    Canvas canvas,
    Size size,
    double thickness,
    Paint paint,
  ) {
    Path path = Path();

    int i = 0; // Index in the points list of the pencil info
    for (PencilCommand command in info.commands) {
      switch (command) {
        case PencilCommand.MOVE_TO:
          path.moveTo(
            info.points[i].x * controller.bounds.width / 100,
            info.points[i].y * controller.bounds.height / 100,
          );
          i++;
          break;

        case PencilCommand.LINE_TO:
          path.lineTo(
            info.points[i].x * controller.bounds.width / 100,
            info.points[i].y * controller.bounds.height / 100,
          );
          break;

        case PencilCommand.QUADRATIC_CURVE_TO:
          path.quadraticBezierTo(
            info.points[i].x * controller.bounds.width / 100,
            info.points[i].y * controller.bounds.height / 100,
            info.points[i + 1].x * controller.bounds.width / 100,
            info.points[i + 1].y * controller.bounds.height / 100,
          );
          i += 2;
          break;

        case PencilCommand.CUBIC_CURVE_TO:
          path.cubicTo(
            info.points[i].x * controller.bounds.width / 100,
            info.points[i].y * controller.bounds.height / 100,
            info.points[i + 1].x * controller.bounds.width / 100,
            info.points[i + 1].y * controller.bounds.height / 100,
            info.points[i + 2].x * controller.bounds.width / 100,
            info.points[i + 2].y * controller.bounds.height / 100,
          );
          i += 3;
          break;

        default:
          throw new Exception("Pencil command '${command.toString()}' unknown");
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
