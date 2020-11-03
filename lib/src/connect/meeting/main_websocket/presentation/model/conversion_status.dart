/// Current conversion status.
class ConversionStatus {
  /// Status of the conversion.
  String status;

  /// Whether an error happened.
  bool error;

  /// Whether the conversion is done.
  bool done;

  /// Amount of pages already converted.
  int pagesCompleted;

  /// Total amount of pages.
  final int numPages;

  ConversionStatus({
    this.status,
    this.error,
    this.done,
    this.pagesCompleted,
    this.numPages,
  });
}
