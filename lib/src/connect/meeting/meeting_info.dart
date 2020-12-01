/// Info needed to join a meeting.
class MeetingInfo {
  /// URL of the meeting.
  String _meetingUrl;

  /// URL used to join the meeting.
  String _joinUrl;

  /// Token of the current session.
  String _sessionToken;

  /// Cookie used to authenticate with the BBB server.
  String _cookie;

  /// Name of the conference.
  String _conferenceName;

  /// The full user name.
  String _fullUserName;

  /// ID of the meeting.
  String _meetingID;

  /// Extern meeting ID.
  String _externMeetingID;

  /// Extern user ID.
  String _externUserID;

  /// Internal user ID.
  String _internalUserID;

  /// Authentication token.
  String _authToken;

  /// Role of the user.
  String _role;

  /// ID of the conference.
  String _conference;

  /// ID of the room.
  String _room;

  /// Voice bridge to use.
  String _voiceBridge;

  /// Number used to dial into the conference.
  String _dialNumber;

  /// Web voice conference.
  String _webVoiceConf;

  /// URL to logout the user.
  String _logoutUrl;

  /// Whether the room is a breakout room.
  bool _isBreakout;

  /// Whether to mute the user on start.
  bool _muteOnStart;

  /// STUN / TURN servers.
  Map<String, dynamic> _iceServers;

  MeetingInfo({
    String meetingUrl,
    String joinUrl,
    String sessionToken,
    String cookie,
    String conferenceName,
    String fullUserName,
    String meetingID,
    String externMeetingID,
    String externUserID,
    String internalUserID,
    String authToken,
    String role,
    String conference,
    String room,
    String voiceBridge,
    String dialNumber,
    String webVoiceConf,
    String logoutUrl,
    bool isBreakout = false,
    bool muteOnStart = true,
    Map<String, dynamic> iceServers,
  })  : this._meetingUrl = meetingUrl,
        this._joinUrl = joinUrl,
        this._sessionToken = sessionToken,
        this._cookie = cookie,
        this._conferenceName = conferenceName,
        this._fullUserName = fullUserName,
        this._meetingID = meetingID,
        this._externMeetingID = externMeetingID,
        this._externUserID = externUserID,
        this._internalUserID = internalUserID,
        this._authToken = authToken,
        this._role = role,
        this._conference = conference,
        this._room = room,
        this._voiceBridge = voiceBridge,
        this._dialNumber = dialNumber,
        this._webVoiceConf = webVoiceConf,
        this._isBreakout = isBreakout,
        this._muteOnStart = muteOnStart,
        this._logoutUrl = logoutUrl,
        this._iceServers = iceServers;

  bool get muteOnStart => _muteOnStart;

  bool get isBreakout => _isBreakout;

  String get logoutUrl => _logoutUrl;

  String get webVoiceConf => _webVoiceConf;

  String get dialNumber => _dialNumber;

  String get voiceBridge => _voiceBridge;

  String get room => _room;

  String get conference => _conference;

  String get role => _role;

  String get authToken => _authToken;

  String get internalUserID => _internalUserID;

  String get externUserID => _externUserID;

  String get externMeetingID => _externMeetingID;

  String get meetingID => _meetingID;

  String get fullUserName => _fullUserName;

  String get conferenceName => _conferenceName;

  String get cookie => _cookie;

  String get sessionToken => _sessionToken;

  String get joinUrl => _joinUrl;

  String get meetingUrl => _meetingUrl;

  Map<String, dynamic> get iceServers => _iceServers;
}
