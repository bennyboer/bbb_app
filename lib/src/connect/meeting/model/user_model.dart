class UserModel {
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

  String connectionStatus = CONNECTIONSTATUS_OFFLINE;

  UserModel();

  /// Check whether the user is currently online.
  bool isOnline() => connectionStatus == CONNECTIONSTATUS_ONLINE;
}
