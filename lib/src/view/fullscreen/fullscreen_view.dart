import 'package:flutter/material.dart';

/// View displaying a passed widget full screen.
class FullscreenView extends StatefulWidget {
  /// Child to display fullscreen.
  final Widget _child;

  FullscreenView({
    @required Widget child,
  }) : _child = child;

  @override
  State<StatefulWidget> createState() => _FullscreenViewState();
}

/// State of the fullscreen view.
class _FullscreenViewState extends State<FullscreenView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Stack(
            children: [
              widget._child,
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.fullscreen_exit),
                  color: Colors.grey,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
