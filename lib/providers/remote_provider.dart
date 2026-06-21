import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/samsung_service.dart';

class RemoteState {
  final SamsungStatus status;
  final String? error;

  const RemoteState({this.status = SamsungStatus.disconnected, this.error});

  RemoteState copyWith({SamsungStatus? status, String? error}) => RemoteState(
        status: status ?? this.status,
        error: error,
      );
}

class RemoteNotifier extends StateNotifier<RemoteState> {
  final SamsungService _svc;
  final String ip;

  // ignore: unused_field
  bool _intentionalDisconnect = false;
  // ignore: unused_field
  bool _reconnecting = false;
  // ignore: unused_field
  bool _didAutoReconnect = false;

  RemoteNotifier(this._svc, this.ip) : super(const RemoteState());

  Future<void> connect() async {
    _intentionalDisconnect = false;
    _reconnecting = false;
    _didAutoReconnect = false;
    state = state.copyWith(status: SamsungStatus.connecting);
    // TODO: connect via _svc, handle token auth, update state
  }

  Future<void> sendKey(String keyCode) async {
    await _svc.sendKey(keyCode);
  }

  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    await _svc.disconnect();
    state = state.copyWith(status: SamsungStatus.disconnected);
  }

  @override
  void dispose() {
    _svc.dispose();
    super.dispose();
  }
}

final remoteProvider =
    StateNotifierProvider.family.autoDispose<RemoteNotifier, RemoteState, String>(
  (ref, ip) => RemoteNotifier(SamsungService(), ip),
);
