import 'dart:async';

import 'package:bbb_app/src/connect/meeting/main_websocket/main_websocket.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/slide/presentation_slide.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/presentation.dart';
import 'package:bbb_app/src/view/main/presentation/presentation_painter.dart';
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

  /// SVG to paint.
  DrawableRoot _slideSvg;

  /// Subscription to slide events.
  StreamSubscription<PresentationSlideEvent> _slideEventSubscription;

  @override
  void initState() {
    super.initState();

    _currentSlide = widget._mainWebSocket.presentationModule.currentSlide;
    _slideEventSubscription = widget
        ._mainWebSocket.presentationModule.slideEventsStream
        .listen((event) {
      if (event.slide.current) {
        _currentSlide = event.slide;
        _reloadSVG(_currentSlide.svgUri);
      }
    });

    if (_currentSlide != null) {
      _reloadSVG(_currentSlide.svgUri);
    }
  }

  /// Reload the SVG from the passed [url].
  Future<void> _reloadSVG(String url) async {
    http.Response response = await http.get(url);

    _slideSvg = await svg.fromSvgString(response.body, response.body);

    //check if this widget is still in tree. (might have been removed from tree during the http.get)
    if(mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _slideEventSubscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
        child: _currentSlide != null && _currentSlide.bounds != null
            ? AspectRatio(
                aspectRatio:
                    _currentSlide.bounds.width / _currentSlide.bounds.height,
                child: ClipRect(
                  child: CustomPaint(
                    painter: PresentationPainter(
                      _slideSvg,
                      _currentSlide.bounds,
                      _currentSlide.annotations.values.toList(growable: false)
                        ..sort((o1, o2) => o1.position.compareTo(o2.position)),
                    ),
                  ),
                ),
              )
            : const CircularProgressIndicator(),
      );
}
