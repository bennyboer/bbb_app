import 'package:sip_ua/sip_ua.dart';

class CustomSIPUAHelper extends SIPUAHelper {
  @override
  Map<String, Object> buildCallOptions([bool voiceonly = false]) {
    Map<String, Object> options = super.buildCallOptions(voiceonly);

    Map<String, dynamic> peerConnectionConfig = options['pcConfig'];
    peerConnectionConfig['sdpSemantics'] = 'unified-plan';

    return options;
  }
}
