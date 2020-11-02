/// Bounds of a presentation slide.
class SlideBounds {
  /// X-Position in the slide.
  double x;

  /// Y-Position in the slide.
  double y;

  /// Slide width.
  double width;

  /// Slide height.
  double height;

  /// Current width of the view box.
  double viewBoxWidth;

  /// Current height of the view box.
  double viewBoxHeight;

  SlideBounds({
    this.x,
    this.y,
    this.width,
    this.height,
    this.viewBoxWidth,
    this.viewBoxHeight,
  });
}
