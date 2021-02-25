/// Representation of a BBB meeting user.
class User {
  static const String ROLE_MODERATOR = "MODERATOR";
  static const String CONNECTIONSTATUS_ONLINE = "online";
  static const String CONNECTIONSTATUS_OFFLINE = "offline";

  /// ID of the user.
  /// Sometimes referred to as "internal" ID.
  final String id;

  String name = "";

  String sortName = "";

  String color = "";

  String role = "VIEWER";

  bool isPresenter = false;

  bool talking = false;

  bool listenOnly = false;

  bool muted = false;

  bool joined = false;

  /// Whether the user has been ejected from the conference.
  /// For example when the user has been kicked by a moderator.
  bool ejected = false;

  String connectionStatus = CONNECTIONSTATUS_OFFLINE;

  User(this.id);

  /// Check whether the user is currently online.
  bool isOnline() => connectionStatus == CONNECTIONSTATUS_ONLINE;
}
