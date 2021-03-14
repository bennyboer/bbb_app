import 'dart:math';

import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/annotation/annotation.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/slide/slide_bounds.dart';
import 'package:flutter/material.dart';

/// Controller for the presentation painter.
class PresentationPainterController extends ChangeNotifier {
  /// Bounds of the slide.
  SlideBounds _bounds;

  /// Annotations to draw.
  List<Annotation> _annotations;

  /// Current cursor position.
  Point<double> _cursorPos;

  SlideBounds get bounds => _bounds;

  set bounds(SlideBounds value) {
    _bounds = value;
    notifyListeners();
  }

  List<Annotation> get annotations => _annotations;

  set annotations(List<Annotation> value) {
    _annotations = value;
    notifyListeners();
  }

  Point<double> get cursorPos => _cursorPos;

  set cursorPos(Point<double> value) {
    _cursorPos = value;
    notifyListeners();
  }
}
