class UserModel {

  static String ROLE_MODERATOR = "MODERATOR";
  static String CONNECTIONSTATUS_ONLINE = "online";


  String id = "";

  String name = "";

  String sortName = "";

  String internalId = "";

  String color = "";

  String role = "VIEWER";

  bool isPresenter = false;

  String connectionStatus = "offline";

  UserModel();
}