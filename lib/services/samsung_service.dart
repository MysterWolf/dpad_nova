import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum SamsungStatus { disconnected, connecting, authorizing, connected, ready, error }

class SamsungService {
  static const _appName = 'DPadNova';
  static const _tokenKeyPrefix = 'samsung_token_';

  String _ip = '';
  SamsungStatus _status = SamsungStatus.disconnected;
  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  bool _intentionalDisconnect = false;
  bool _reconnecting = false;
  bool _didAutoReconnect = false;

  SamsungStatus get status => _status;

  void Function(SamsungStatus)? onStatusChange;
  void Function(String)? onError;

  void _setStatus(SamsungStatus s) {
    _status = s;
    onStatusChange?.call(s);
  }

  Future<void> connect(String ip) async {
    _ip = ip;
    _intentionalDisconnect = false;
    _reconnecting = false;
    _didAutoReconnect = false;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    _setStatus(SamsungStatus.connecting);

    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('$_tokenKeyPrefix$_ip') ?? '';

    WebSocketChannel channel;
    try {
      channel = await _openChannel(_ip, storedToken);
    } catch (e) {
      _setStatus(SamsungStatus.error);
      onError?.call(e.toString());
      return;
    }

    _channel = channel;
    _setStatus(storedToken.isEmpty ? SamsungStatus.authorizing : SamsungStatus.connected);

    _channel!.sink.add(jsonEncode({
      'method': 'ms.channel.connect',
      'params': {
        'name': _appName,
        'token': storedToken,
      },
    }));

    _sub = _channel!.stream.listen(
      _onData,
      onError: _onStreamError,
      onDone: _onDone,
      cancelOnError: false,
    );
  }

  // Tries wss first; falls back to ws if TLS handshake fails (varies by model).
  Future<WebSocketChannel> _openChannel(String ip, String token) async {
    final query = token.isNotEmpty ? '?token=$token' : '';
    final path = '/api/v2/channels/samsung.remote.control$query';

    try {
      final ch = WebSocketChannel.connect(Uri.parse('wss://$ip:8002$path'));
      await ch.ready;
      return ch;
    } catch (_) {
      final ch = WebSocketChannel.connect(Uri.parse('ws://$ip:8002$path'));
      await ch.ready;
      return ch;
    }
  }

  void _onData(dynamic raw) {
    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final event = msg['event'] as String?;
    if (event == 'ms.channel.connect') {
      final token = _extractToken(msg['data']);
      if (token != null && token.isNotEmpty) {
        SharedPreferences.getInstance().then(
          (prefs) => prefs.setString('$_tokenKeyPrefix$_ip', token),
        );
      }
      _setStatus(SamsungStatus.ready);
    }
  }

  // Token may be in data.token (String), data (String JSON), or data (Map).
  String? _extractToken(dynamic data) {
    if (data is Map) {
      return data['token'] as String?;
    }
    if (data is String) {
      try {
        final decoded = jsonDecode(data) as Map<String, dynamic>;
        return decoded['token'] as String?;
      } catch (_) {}
    }
    return null;
  }

  void _onStreamError(dynamic error) {
    _setStatus(SamsungStatus.error);
    onError?.call(error.toString());
  }

  void _onDone() {
    if (_intentionalDisconnect) {
      _setStatus(SamsungStatus.disconnected);
      return;
    }
    if (!_reconnecting && !_didAutoReconnect) {
      _reconnecting = true;
      _didAutoReconnect = true;
      Future.delayed(const Duration(seconds: 2), () async {
        _reconnecting = false;
        if (!_intentionalDisconnect) await _doConnect();
      });
    } else {
      _setStatus(SamsungStatus.disconnected);
    }
  }

  Future<void> sendKey(String keyCode) async {
    if (_channel == null || _status != SamsungStatus.ready) return;
    _channel!.sink.add(jsonEncode({
      'method': 'ms.remote.control',
      'params': {
        'Cmd': 'Click',
        'DataOfCmd': keyCode,
        'Option': 'false',
        'TypeOfRemote': 'SendRemoteKey',
      },
    }));
  }

  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    await _sub?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _setStatus(SamsungStatus.disconnected);
  }

  void dispose() {
    _intentionalDisconnect = true;
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
  }
}
