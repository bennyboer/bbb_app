import 'package:bbb_app/src/connect/meeting/main_websocket/module.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/user/user.dart';
import 'package:bbb_app/src/connect/meeting/model/user_model.dart';

const String VOICE_USERS = "voiceUsers";

class VoiceUsersModule extends Module {
  UserModule _userModule;
  Map<String, String> _voiceIdToInternalId = {};

  VoiceUsersModule(messageSender, this._userModule) : super(messageSender);

  @override
  void onConnected() {
    subscribe("voiceUsers");
  }

  @override
  Future<void> onDisconnect() {
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
    UserModel model;

    if (method == "added") {
      model = _userModule.userMapByInternalId.putIfAbsent(fields["intId"], () => UserModel());
      model.muted = fields["muted"];
      model.listenOnly = fields["listenOnly"];
      model.joined = fields["joined"];
      _voiceIdToInternalId[msg["id"]] = model.internalId;
    } else if (method == "changed") {
      model = _userModule.userMapByInternalId[_voiceIdToInternalId[msg["id"]]];
    }
    if (fields["talking"] != null)
      model.talking = fields["talking"];
    _userModule.updateUserForId(fields["intId"], model);
  }
}
