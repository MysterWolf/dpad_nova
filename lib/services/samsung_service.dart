// Samsung SmartThings local WebSocket remote control service.
//
// Protocol:
//   WebSocket: wss://{ip}:8002/api/v2/channels/samsung.remote.control
//   Auth token stored in SharedPreferences under samsung_token_{ip}.
//   Token replayed on every connection — no re-authorization loop once paired.
//
// Key event format:
//   {
//     "method": "ms.remote.control",
//     "params": {
//       "Cmd": "Click",
//       "DataOfCmd": "KEY_*",
//       "Option": "false",
//       "TypeOfRemote": "SendRemoteKey"
//     }
//   }
//
// Auto-reconnect: fires once on unexpected disconnect (same 3-flag guard as
// DPad Pilot: _intentionalDisconnect, _reconnecting, _didAutoReconnect).

enum SamsungStatus { disconnected, connecting, authenticating, connected, error }

class SamsungService {
  // TODO: implement WebSocket connection, token auth, and key event sending
  SamsungStatus get status => SamsungStatus.disconnected;

  Future<void> connect(String ip) async {
    throw UnimplementedError('SamsungService.connect not yet implemented');
  }

  Future<void> sendKey(String keyCode) async {
    throw UnimplementedError('SamsungService.sendKey not yet implemented');
  }

  Future<void> disconnect() async {
    throw UnimplementedError('SamsungService.disconnect not yet implemented');
  }

  void dispose() {}
}
