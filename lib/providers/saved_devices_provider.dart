import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/saved_device.dart';
import '../services/saved_devices_service.dart';

class SavedDevicesNotifier extends StateNotifier<List<SavedDevice>> {
  final SavedDevicesService _svc;

  SavedDevicesNotifier(this._svc, {List<SavedDevice> initial = const []})
      : super(initial);

  Future<void> add(SavedDevice device) async {
    state = await _svc.add(state, device);
  }

  Future<void> remove(String ip) async {
    state = await _svc.remove(state, ip);
  }

  Future<void> rename(String ip, String name) async {
    state = await _svc.rename(state, ip, name);
  }

  Future<void> updateLastSeen(String ip) async {
    state = await _svc.updateLastSeen(state, ip);
  }

  void init(List<SavedDevice> devices) => state = devices;

  bool isSaved(String ip) => state.any((d) => d.ip == ip);

  SavedDevice? find(String ip) {
    for (final d in state) {
      if (d.ip == ip) return d;
    }
    return null;
  }
}

final savedDevicesProvider =
    StateNotifierProvider<SavedDevicesNotifier, List<SavedDevice>>(
  (ref) => SavedDevicesNotifier(SavedDevicesService()),
);
