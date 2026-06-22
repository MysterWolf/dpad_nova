import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/samsung_app_launcher.dart';
import '../services/samsung_service.dart';

enum TvConnectionState { connected, connecting, disconnected }

class RemoteState {
  final SamsungStatus status;
  final String? error;

  const RemoteState({this.status = SamsungStatus.disconnected, this.error});

  bool get isActive =>
      status == SamsungStatus.connected || status == SamsungStatus.ready;
  bool get isReady => status == SamsungStatus.ready;
  bool get isAuthorizing => status == SamsungStatus.authorizing;
  bool get isConnecting => status == SamsungStatus.connecting;
  bool get isError => status == SamsungStatus.error;

  TvConnectionState get connectionState => switch (status) {
        SamsungStatus.connected || SamsungStatus.ready =>
          TvConnectionState.connected,
        SamsungStatus.connecting || SamsungStatus.authorizing =>
          TvConnectionState.connecting,
        _ => TvConnectionState.disconnected,
      };

  RemoteState copyWith({SamsungStatus? status, String? error}) => RemoteState(
        status: status ?? this.status,
        error: error,
      );
}

class RemoteNotifier extends StateNotifier<RemoteState> {
  final SamsungService _svc;
  final SamsungAppLauncher _launcher;
  final String ip;

  RemoteNotifier(this._svc, this._launcher, this.ip)
      : super(const RemoteState()) {
    _svc.onStatusChange = (s) {
      if (mounted) state = RemoteState(status: s);
    };
    _svc.onError = (e) {
      if (mounted) state = state.copyWith(status: SamsungStatus.error, error: e);
    };
  }

  Future<void> connect() => _svc.connect(ip);

  Future<void> disconnect() => _svc.disconnect();

  Future<void> reconnect() async {
    await _svc.disconnect();
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) await _svc.connect(ip);
  }

  Future<void> sendKey(String keyCode) => _svc.sendKey(keyCode);

  void volumeUp() => sendKey(SamsungKey.volumeUp);
  void volumeDown() => sendKey(SamsungKey.volumeDown);
  void channelUp() => sendKey(SamsungKey.channelUp);
  void channelDown() => sendKey(SamsungKey.channelDown);
  void powerOff() => sendKey(SamsungKey.power);

  Future<void> launchApp(String appId) => _launcher.launchApp(appId);

  void insertText(String text) {
    for (final rune in text.runes) {
      final ch = String.fromCharCode(rune).toUpperCase();
      sendKey(ch == ' ' ? 'KEY_SPACE' : 'KEY_$ch');
    }
  }

  void deleteChar() => sendKey('KEY_DELETE');

  @override
  void dispose() {
    _svc.dispose();
    super.dispose();
  }
}

// Samsung key constants — used by RemoteNotifier and remote_screen.dart.
class SamsungKey {
  static const home = 'KEY_HOME';
  static const back = 'KEY_RETURN';
  static const up = 'KEY_UP';
  static const down = 'KEY_DOWN';
  static const left = 'KEY_LEFT';
  static const right = 'KEY_RIGHT';
  static const enter = 'KEY_ENTER';
  static const volumeUp = 'KEY_VOLUP';
  static const volumeDown = 'KEY_VOLDOWN';
  static const mute = 'KEY_MUTE';
  static const channelUp = 'KEY_CHUP';
  static const channelDown = 'KEY_CHDOWN';
  static const power = 'KEY_POWER';
  static const menu = 'KEY_MENU';
  static const play = 'KEY_PLAY';
  static const pause = 'KEY_PAUSE';
  static const rewind = 'KEY_REWIND';
  static const fastForward = 'KEY_FF';
  static const source = 'KEY_SOURCE';
}

final remoteProvider =
    StateNotifierProvider.family.autoDispose<RemoteNotifier, RemoteState, String>(
  (ref, ip) => RemoteNotifier(SamsungService(), SamsungAppLauncher(), ip),
);
