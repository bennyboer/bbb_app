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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlideBounds &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          width == other.width &&
          height == other.height &&
          viewBoxWidth == other.viewBoxWidth &&
          viewBoxHeight == other.viewBoxHeight;
}
