import 'info/annotation_info.dart';

/// Annotation on slides.
class Annotation {
  /// ID of the slide or whiteboard the annotation belongs to.
  final String whiteboardId;

  /// ID of the user the annotation belongs to.
  final String userId;

  /// ID of the annotation itself.
  final String annotationId;

  /// Current status of the annotation.
  String status;

  /// Type of the annotation (pencil, circle, text, ...).
  String annotationType;

  /// Position of the annotation on the slide (z-axis).
  /// This determines what annotations lay above each other.
  int position;

  /// Info for the annotation type.
  AnnotationInfo info;

  Annotation({
    this.whiteboardId,
    this.userId,
    this.annotationId,
    this.status,
    this.position,
    this.annotationType,
    this.info,
  });
}
