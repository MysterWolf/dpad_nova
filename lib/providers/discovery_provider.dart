import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/samsung_device.dart';
import '../services/samsung_discovery_service.dart';

class DiscoveryState {
  final List<SamsungDevice> devices;
  final bool isScanning;

  const DiscoveryState({this.devices = const [], this.isScanning = false});

  DiscoveryState copyWith({List<SamsungDevice>? devices, bool? isScanning}) =>
      DiscoveryState(
        devices: devices ?? this.devices,
        isScanning: isScanning ?? this.isScanning,
      );
}

class DiscoveryNotifier extends StateNotifier<DiscoveryState> {
  final SamsungDiscoveryService _svc;

  DiscoveryNotifier(this._svc) : super(const DiscoveryState());

  Future<void> scan() async {
    state = state.copyWith(isScanning: true, devices: []);
    final found = await _svc.scanMdns();
    if (mounted) state = state.copyWith(devices: found, isScanning: false);
  }

  /// REST probe: confirms a Samsung TV at [ip] and returns it with its
  /// friendly name. Returns null if the IP is not a Samsung TV.
  Future<SamsungDevice?> probe(String ip) => _svc.probe(ip);

  void reset() => state = const DiscoveryState();
}

final discoveryProvider =
    StateNotifierProvider.autoDispose<DiscoveryNotifier, DiscoveryState>(
  (ref) => DiscoveryNotifier(SamsungDiscoveryService()),
);
