import 'package:bbb_app/src/broadcast/ModuleBlocProvider.dart';
import 'package:bbb_app/src/broadcast/user_voice_status_bloc.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/module.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/user/model/user_model.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/user/user.dart';

const String VOICE_USERS = "voiceUsers";

/// Apparently, the Voice Users in BBB are somewhat separate from the regular users.
/// Because we want to simplify things, we use the same data for both.
class VoiceUsersModule extends Module {
  UserModule _userModule;
  ModuleBlocProvider _provider;
  String _userIntId;

  /// voice users have their own, unique message id which is mapped to the users internal id
  /// on method: "add".
  Map<String, String> _voiceIdToInternalId = {};

  VoiceUsersModule(messageSender, this._userModule, this._provider, this._userIntId) : super(messageSender);

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
      model = _userModule.userMapByInternalId
          .putIfAbsent(fields["intId"], () => UserModel());
      model.internalId = fields["intId"];
      model.listenOnly = fields["listenOnly"];
      model.joined = fields["joined"];
      _voiceIdToInternalId[msg["id"]] = model.internalId;
    } else if (method == "changed") {
      model = _userModule.userMapByInternalId[_voiceIdToInternalId[msg["id"]]];
    }
    if (fields["talking"] != null) model.talking = fields["talking"];
    if (fields["muted"] != null) model.talking = fields["talking"];
    if (model.internalId == _userIntId) {
      if (model.muted) {
        _provider.userVoiceStatusBloc.add(UserVoiceStatusEvent.mute);
      } else {
        _provider.userVoiceStatusBloc.add(UserVoiceStatusEvent.unmute);
      }
    }
    _userModule.updateUserForId(model.internalId, model);
  }
}
