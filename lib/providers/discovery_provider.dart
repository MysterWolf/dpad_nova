import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ScanStatus { idle, scanning, done, error }

class DiscoveryState {
  final ScanStatus status;
  final List<String> found;

  const DiscoveryState({this.status = ScanStatus.idle, this.found = const []});

  DiscoveryState copyWith({ScanStatus? status, List<String>? found}) =>
      DiscoveryState(
        status: status ?? this.status,
        found: found ?? this.found,
      );
}

class DiscoveryNotifier extends StateNotifier<DiscoveryState> {
  DiscoveryNotifier() : super(const DiscoveryState());

  // TODO: implement mDNS / REST probe scan
  Future<void> scan() async {
    state = state.copyWith(status: ScanStatus.scanning, found: []);
    // placeholder
    state = state.copyWith(status: ScanStatus.done);
  }

  void reset() => state = const DiscoveryState();
}

final discoveryProvider =
    StateNotifierProvider.autoDispose<DiscoveryNotifier, DiscoveryState>(
  (ref) => DiscoveryNotifier(),
);
