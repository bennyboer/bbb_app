/// Page of a presentation.
class PresentationPage {
  /// ID of the page.
  final String pageId;

  /// Page number.
  final int num;

  /// Whether it is the currently shown page.
  bool current;

  /// Current X-Offset.
  int xOffset;

  /// Current Y-Offset.
  int yOffset;

  /// Width ratio.
  int widthRatio;

  /// Height ratio.
  int heightRatio;

  /// URI of the thumbnail.
  String thumbUri;

  /// URI of the SWF.
  String swfUri;

  /// URI of the text form of the slide.
  String txtUri;

  /// URI of the SVG form of the slide.
  String svgUri;

  PresentationPage({
    this.pageId,
    this.num,
    this.current,
    this.xOffset,
    this.yOffset,
    this.widthRatio,
    this.heightRatio,
    this.thumbUri,
    this.swfUri,
    this.txtUri,
    this.svgUri,
  });
}
