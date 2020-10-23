import 'dart:convert';
import 'dart:core';

import 'package:bbb_app/src/broadcast/app_state_notifier.dart';
import 'package:bbb_app/src/utils/websocket.dart';
import 'package:bbb_app/src/view/start/start_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';


SimpleWebSocket _socket;
RTCPeerConnection _pc;
RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

/// Entry point of the application.
Future main() async {
  runApp(
    ChangeNotifierProvider<AppStateNotifier>(
      create: (context) => AppStateNotifier(),
      child: BBBApp(),
    ),
  );
}

/// Main widget of the BBB app.
class BBBApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateNotifier>(
      builder: (context, appState, child) => MaterialApp(
        title: 'BBB App',
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark().copyWith(
          appBarTheme: AppBarTheme(color: const Color(0xFF253341)),
          scaffoldBackgroundColor: const Color(0xFF15202B),
        ),
        themeMode: appState.darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
        home: StartView(),
      ),
    );
  }
}

//class _BBBAppState extends State<BBBApp> {
//  /// Whether dark mode is enabled.
//  bool _isDarkModeEnabled = false;
//
//  @override
//  void initState() {
//    super.initState();
//
//    _remoteRenderer.initialize().then((value) => connect());
//  }
//
//  @override
//  void dispose() {
//    super.dispose();
//  }
//
//  @override
//  Widget build(BuildContext context) {
////    return MaterialApp(
////      title: 'BBB App',
////      home: VideoPage(),
////    );
//
////    return MaterialApp(
////      title: 'Day / night switcher example',
////      theme: ThemeData.light(),
////      darkTheme: ThemeData.dark().copyWith(
////        appBarTheme: AppBarTheme(color: const Color(0xFF253341)),
////        scaffoldBackgroundColor: const Color(0xFF15202B),
////      ),
////      themeMode: _isDarkModeEnabled ? ThemeMode.dark : ThemeMode.light,
////      home: Scaffold(
////        appBar: AppBar(title: Text("BBB App")),
////        body: SizedBox.expand(
////          child: Column(
////            crossAxisAlignment: CrossAxisAlignment.center,
////            mainAxisSize: MainAxisSize.max,
////            mainAxisAlignment: MainAxisAlignment.center,
////            children: [
////              DayNightSwitcher(
////                isDarkModeEnabled: _isDarkModeEnabled,
////                onStateChanged: (isDarkModeEnabled) =>
////                    setState(() => this._isDarkModeEnabled = isDarkModeEnabled),
////              ),
////            ],
////          ),
////        ),
////      ),
////    );
//
//    return MaterialApp(
//        title: 'Day / night switcher example',
//        theme: ThemeData.light(),
//        darkTheme: ThemeData.dark().copyWith(
//          appBarTheme: AppBarTheme(color: const Color(0xFF253341)),
//          scaffoldBackgroundColor: const Color(0xFF15202B),
//        ),
//        themeMode: _isDarkModeEnabled ? ThemeMode.dark : ThemeMode.light,
//        home: StartView());
//  }
//
////TODO custom TURN/STUN server returned by BBB
//  Map<String, dynamic> _iceServers = {
//    'iceServers': [
//      {'url': 'stun:stun.l.google.com:19302'},
//    ]
//  };
//
//  final Map<String, dynamic> _config = {
//    'mandatory': {},
//    'optional': [
//      {'DtlsSrtpKeyAgreement': true},
//    ],
//  };
//
//  final Map<String, dynamic> _constraints = {
//    'mandatory': {
//      'OfferToReceiveAudio': true,
//      'OfferToReceiveVideo': true,
//    },
//    'optional': [],
//  };
//
//  void connect() async {
//    print("connect!!!");
//
//    var url =
//        'https://bbbXXXXXXX.cs.hm.edu/bbb-webrtc-sfu?sessionToken=XXXXXXXXXX';
//    _socket = SimpleWebSocket(url);
//
//    print('connect to $url');
//
//    _socket.onOpen = () {
//      print('onOpen');
//      createOffer();
//    };
//
//    _socket.onMessage = (message) {
//      print('Received data: ' + message);
//      JsonDecoder decoder = new JsonDecoder();
//      onMessage(decoder.convert(message));
//    };
//
//    _socket.onClose = (int code, String reason) {
//      print('Closed by server [$code => $reason]!');
//    };
//
//    await _socket.connect();
//  }
//
//  send(data) {
//    JsonEncoder encoder = new JsonEncoder();
//    _socket.send(encoder.convert(data));
//  }
//
//  void onMessage(message) async {
//    switch (message['id']) {
//      case 'startResponse':
//        {
//          await _pc.setRemoteDescription(
//              new RTCSessionDescription(message['sdpAnswer'], 'answer'));
//        }
//        break;
//
//      case 'iceCandidate':
//        {
//          RTCIceCandidate candidate = new RTCIceCandidate(
//              message['candidate']['candidate'],
//              message['candidate']['sdpMid'],
//              message['candidate']['sdpMLineIndex']);
//          await _pc.addCandidate(candidate);
//        }
//        break;
//
//      case 'playStart':
//        {
//          print("############################################## playStart");
//          print(_pc.getRemoteStreams());
//          _remoteRenderer.srcObject = _pc.getRemoteStreams()[1];
//        }
//        break;
//
//      default:
//        break;
//    }
//  }
//
//  createOffer() async {
//    try {
//      _pc = await createPeerConnection(_iceServers, _config);
//
//      _pc.onIceCandidate = (candidate) {
//        send({
//          'cameraId': 'XXXXXX',
//          'candidate': {
//            'candidate': candidate.candidate,
//            'sdpMLineIndex': candidate.sdpMlineIndex,
//            'sdpMid': candidate.sdpMid,
//          },
//          'id': 'onIceCandidate',
//          'role': 'viewer',
//          'type': 'video'
//        });
//      };
//
//      //this is never triggered.... using case 'playStart' in onMessage() instead
//      _pc.onAddStream = (stream) {
//        print("############################################## onAddStream");
//        _remoteRenderer.srcObject = stream;
//      };
//
//      _pc.onRemoveStream = (stream) {
//        print("############################################## onRemoveStream");
//        _remoteRenderer.srcObject = null;
//      };
//
//      _pc = await createPeerConnection(_iceServers, _config);
//
//      RTCSessionDescription s = await _pc.createOffer(_constraints);
//      _pc.setLocalDescription(s);
//
//      send({
//        'bitrate': 200,
//        'cameraId': 'XXXXXX',
//        'id': 'start',
//        'meetingId': 'XXXXXX',
//        'record': true,
//        'role': 'viewer',
//        'sdpOffer': s.sdp,
//        'type': 'video',
//        'userId': 'XXXXXX',
//        'userName': 'XXXXXX',
//        'voiceBridge': 'XXXXXX',
//      });
//    } catch (e) {
//      print(e.toString());
//    }
//  }
//}
//
//class VideoPage extends StatelessWidget {
//  @override
//  Widget build(BuildContext context) {
//    return Container(
//      width: 300,
//      height: 400,
//      child: RTCVideoView(_remoteRenderer),
//    );
//  }
//}
