import 'dart:ui';

import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/slide/slide_bounds.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Painter for the presentation SVG.
class PresentationSvgPainter extends CustomPainter {
  /// SVG to draw upon the canvas as base of the presentation slide.
  final DrawableRoot _svg;

  /// Bounds of the slide.
  final SlideBounds _bounds;

  PresentationSvgPainter(
    this._svg,
    this._bounds,
  );

  @override
  void paint(Canvas canvas, Size size) {
    _drawSVG(canvas, size);
  }

  /// Draw the SVG on the canvas.
  void _drawSVG(Canvas canvas, Size size) {
    if (_svg == null) {
      return;
    }

    double zoomFactor = size.width / _bounds.viewBoxWidth;

    canvas.scale(zoomFactor, zoomFactor);
    canvas.translate(-_bounds.x, -_bounds.y);

    _svg.draw(canvas, Rect.fromLTWH(0.0, 0.0, size.width, size.height));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    PresentationSvgPainter oldPainter = oldDelegate;

    return oldPainter._svg != _svg ||
        oldPainter._bounds.height != _bounds.height ||
        oldPainter._bounds.width != _bounds.width ||
        oldPainter._bounds.x != _bounds.x ||
        oldPainter._bounds.y != _bounds.y;
  }
}
