import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'log.dart';

typedef void OnMessageCallback(dynamic msg);
typedef void OnCloseCallback(int code, String reason);
typedef void OnOpenCallback();

class SimpleWebSocket {
  final String _url;
  final String _cookie;
  final Map<String, String> _additionalHeaders;
  WebSocket _socket;
  OnOpenCallback onOpen;
  OnMessageCallback onMessage;
  OnCloseCallback onClose;

  SimpleWebSocket(
    this._url, {
    String cookie,
    Map<String, String> additionalHeaders,
  })  : _cookie = cookie,
        _additionalHeaders = additionalHeaders;

  connect() async {
    try {
      _socket = await _connectForSelfSignedCert(_url, cookie: _cookie);
      this?.onOpen();
      _socket.listen((data) {
        this?.onMessage(data);
      }, onDone: () {
        this?.onClose(_socket.closeCode, _socket.closeReason);
      });
    } catch (e) {
      this.onClose(500, e.toString());
    }
  }

  send(data) {
    if (_socket != null) {
      _socket.add(data);

      Log.verbose("Send message on websocket: '$data'");
    }
  }

  close() {
    if (_socket != null) _socket.close(WebSocketStatus.normalClosure);
  }

  closeWithReason(int reason) {
    if (_socket != null) _socket.close(reason);
  }

  Future<WebSocket> _connectForSelfSignedCert(
    String url, {
    String cookie,
  }) async {
    try {
      Random r = new Random();
      String key = base64.encode(List<int>.generate(16, (_) => r.nextInt(255)));
      HttpClient client = HttpClient(context: SecurityContext());
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        Log.debug(
            "SimpleWebSocket: Allow self-signed certificate => $host:$port");
        return true;
      };

      HttpClientRequest request = await client.getUrl(Uri.parse(url));
      request.headers.add('Connection', 'Upgrade');
      request.headers.add('Upgrade', 'websocket');
      request.headers.add('Sec-WebSocket-Version', '13');
      request.headers.add('Sec-WebSocket-Key', key.toLowerCase());

      if (_additionalHeaders != null) {
        _additionalHeaders.entries.forEach((e) {
          request.headers.add(e.key, e.value);
        });
      }

      if (cookie != null) {
        request.headers.add("Cookie", cookie);
      }

      HttpClientResponse response = await request.close();

      // if(response.statusCode == 400) {
      //   response.transform(utf8.decoder).listen((contents) {
      //     print(contents);
      //   });
      // }

      Socket socket = await response.detachSocket();
      var webSocket = WebSocket.fromUpgradedSocket(
        socket,
        protocol: 'signaling',
        serverSide: false,
      );

      return webSocket;
    } catch (e) {
      throw e;
    }
  }
}
