import 'package:bbb_app/src/broadcast/module_bloc_provider.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/module.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/user/model/user.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/user/user_module.dart';

const String VOICE_USERS = "voiceUsers";

/// Apparently, the Voice Users in BBB are somewhat separate from the regular users.
/// Because we want to simplify things, we use the same data for both.
class VoiceUsersModule extends Module {
  UserModule _userModule;
  ModuleBlocProvider _provider;

  /// Mapping of voice User IDs (those that come with the messages)
  /// and the actual user ID.
  Map<String, String> _voiceUserIDToUserID = {};

  VoiceUsersModule(messageSender, this._userModule, this._provider)
      : super(messageSender);

  @override
  void onConnected() {
    subscribe(VOICE_USERS);
  }

  @override
  Future<void> onDisconnect() async {
    // Nothing to do
  }

  @override
  void processMessage(Map<String, dynamic> msg) {
    String collectionName = msg["collection"];
    if (collectionName != VOICE_USERS) {
      return;
    }

    final String method = msg["msg"];
    final Map<String, dynamic> fields = msg["fields"];

    // Fetch user ID from message
    String userID;
    if (method == "added") {
      userID = fields["intId"];
    } else if (method == "changed") {
      userID = fields["voiceUserId"];
    }

    // If the userID is not defined by now, we need to map it another way
    String voiceUserID = msg["id"];
    if (userID != null) {
      if (!_voiceUserIDToUserID.containsKey(voiceUserID)) {
        _voiceUserIDToUserID[voiceUserID] = userID;
      }
    } else {
      userID = _voiceUserIDToUserID[voiceUserID];
    }

    // Check if user with given user ID is present, otherwise add as temporary
    // data in the user module to be added later to the actual user model.
    User user = _userModule.getUserByID(userID);
    if (user != null) {
      _addFieldsToUser(fields, user);
      _userModule.emitUpdateEvent(user);
    } else {
      user = User(userID);
      _addFieldsToUser(fields, user);

      _userModule.addTmpUserInfo(user);
    }
  }

  /// Add the given fields to the passed user object.
  void _addFieldsToUser(final Map<String, dynamic> fields, User user) {
    if (fields.containsKey("listenOnly"))
      user.listenOnly = fields["listenOnly"];
    if (fields.containsKey("joined")) user.joined = fields["joined"];
    if (fields.containsKey("talking")) user.talking = fields["talking"];
    if (fields.containsKey("muted")) user.muted = fields["muted"];
  }
}
