import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/conversion_status.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/presentation/model/presentation_page.dart';

/// A presentation representation.
class Presentation {
  /// ID of the presentation.
  final String id;

  /// Pod ID.
  final String podId;

  /// Name of the presentation.
  final String name;

  /// Whether it is the currently shown presentation.
  bool current;

  /// Whether the presentation is downloadable.
  bool downloadable;

  /// Current conversion status of the presentation.
  ConversionStatus conversionStatus;

  /// List of pages in the presentation.
  List<PresentationPage> pages;

  Presentation({
    this.id,
    this.podId,
    this.name,
    this.current,
    this.downloadable,
    this.conversionStatus,
    this.pages,
  });
}
