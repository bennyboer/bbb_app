/// Representation of a BBB meeting user.
class User {
  static const String ROLE_MODERATOR = "MODERATOR";
  static const String CONNECTIONSTATUS_ONLINE = "online";
  static const String CONNECTIONSTATUS_OFFLINE = "offline";

  String name = "";

  String sortName = "";

  String internalId = "";

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

  User();

  /// Check whether the user is currently online.
  bool isOnline() => connectionStatus == CONNECTIONSTATUS_ONLINE;
}
