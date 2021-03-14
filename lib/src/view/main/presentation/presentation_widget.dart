import 'dart:async';

import 'package:bbb_app/src/connect/meeting/main_websocket/main_websocket.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/presentation.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/slide/presentation_slide.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/slide/slide_bounds.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/presentation.dart';
import 'package:bbb_app/src/view/fullscreen/fullscreen_view.dart';
import 'package:bbb_app/src/view/main/presentation/presentation_painter.dart';
import 'package:bbb_app/src/view/main/presentation/presentation_painter_controller.dart';
import 'package:bbb_app/src/view/main/presentation/presentation_svg_painter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

/// Widget showing a meetings presentation.
class PresentationWidget extends StatefulWidget {
  /// Main websocket connection of the meeting.
  final MainWebSocket _mainWebSocket;

  PresentationWidget(this._mainWebSocket);

  @override
  State<StatefulWidget> createState() => _PresentationWidgetState();
}

/// State of the presentation widget.
class _PresentationWidgetState extends State<PresentationWidget> {
  /// Currently shown slide.
  PresentationSlide _currentSlide;

  /// Current slide bounds.
  SlideBounds _slideBounds;

  /// SVG to paint.
  DrawableRoot _slideSvg;

  /// Controller for the presentation painter.
  PresentationPainterController _painterController =
      PresentationPainterController();

  /// Subscription to slide events.
  StreamSubscription<PresentationSlideEvent> _slideEventSubscription;

  /// Whether the widget is currently shown in fullscreen mode.
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
  }

  /// Reload the SVG from the passed [url].
  Future<void> _reloadSVG(String url) async {
    http.Response response = await http.get(url);

    DrawableRoot svgRoot =
        await svg.fromSvgString(response.body, response.body);

    setState(() {
      _slideSvg = svgRoot;
    });
  }

  @override
  void dispose() {
    _slideEventSubscription.cancel();

    super.dispose();
  }

  /// Build the presentation content widget.
  Widget _buildPresentation(SlideBounds bounds) {
    return AspectRatio(
      aspectRatio: bounds.width / bounds.height,
      child: ClipRect(
        child: Stack(
          children: [
            CustomPaint(
              painter: PresentationSvgPainter(
                _slideSvg,
                bounds,
              ),
              size: Size(
                MediaQuery.of(context).size.width,
                MediaQuery.of(context).size.height,
              ),
              isComplex: true,
            ),
            CustomPaint(
              painter: PresentationPainter(_painterController),
              size: Size(
                MediaQuery.of(context).size.width,
                MediaQuery.of(context).size.height,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentSlide != null && _currentSlide.bounds != null) {
      return LayoutBuilder(builder: (context, constraints) {
        Widget presentation = _buildPresentation(_currentSlide.bounds);

        return Center(
          child: Container(
            decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).textTheme.bodyText1.color)),
            child: AspectRatio(
              aspectRatio:
                  _currentSlide.bounds.width / _currentSlide.bounds.height,
              child: Stack(
                children: [
                  presentation,
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: Icon(_isFullscreen
                          ? Icons.fullscreen_exit
                          : Icons.fullscreen),
                      color: Colors.grey,
                      onPressed: () {
                        setState(() {
                          _isFullscreen = !_isFullscreen;
                        });

                        if (_isFullscreen) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  FullscreenView(child: this.widget),
                            ),
                          ).then((_) {
                            setState(() {
                              _isFullscreen = false;
                            });
                          });
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      });
    } else {
      if (_slideEventSubscription == null) {
        _initializeSlideEventSubscription();
      }

      return Center(child: CircularProgressIndicator());
    }
  }

  void _initializeSlideEventSubscription() {
    _currentSlide = widget._mainWebSocket.presentationModule.currentSlide;
    _slideEventSubscription = widget
        ._mainWebSocket.presentationModule.slideEventsStream
        .listen((event) {
      Presentation currentPresentation =
          widget._mainWebSocket.presentationModule.currentPresentation;
      if (currentPresentation != null) {
        bool isRelevantEvent = event.eventType == SlideEventType.ADDED ||
            event.eventType == SlideEventType.CHANGED ||
            event.eventType == SlideEventType.ANNOTATIONS_ONLY_CHANGED;

        if (isRelevantEvent &&
            event.slide.current &&
            event.slide.presentationId == currentPresentation.id) {
          // Check if slide to show changed
          if (event.slide != _currentSlide) {
            _currentSlide = event.slide;
            _updateAnnotations();
          }

          // Check if slide bounds changed
          if (_currentSlide.bounds != _slideBounds) {
            _slideBounds = _currentSlide.bounds;
            _painterController.bounds = _slideBounds;
          }

          if (event.eventType == SlideEventType.ANNOTATIONS_ONLY_CHANGED) {
            _updateAnnotations();
          } else {
            if (_slideBounds != null) {
              _reloadSVG(_currentSlide.svgUri);
            }
          }
        }
      }
    });

    if (_currentSlide != null) {
      _slideBounds = _currentSlide.bounds;
      _painterController.bounds = _slideBounds;

      _updateAnnotations();

      _reloadSVG(_currentSlide.svgUri);
    }
  }

  /// Update the shown annotations.
  void _updateAnnotations() {
    _painterController.cursorPos = _currentSlide.cursorPos;
    _painterController.annotations = _currentSlide.annotations.values
        .toList(growable: false)
          ..sort((o1, o2) => o1.position.compareTo(o2.position));
  }
}
