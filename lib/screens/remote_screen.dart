import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/samsung_device.dart';
import '../providers/remote_provider.dart';
import '../services/samsung_service.dart';
import '../widgets/remote_button.dart';
import 'about_screen.dart';

// Samsung key codes. Full list lives in SamsungKey class below.
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
  static const playPause = 'KEY_PLAY';
  static const rewind = 'KEY_REWIND';
  static const fastForward = 'KEY_FF';
  static const source = 'KEY_SOURCE';
}

// Fixed deeplink map — do not use runtime app list discovery.
class SamsungApp {
  static const primeVideo = 'org.tizen.browser';     // TODO: confirm Tizen component
  static const netflix = 'org.tizen.browser';        // TODO: confirm Tizen component
  static const youtube = 'org.tizen.browser';        // TODO: confirm Tizen component
  static const disneyPlus = 'org.tizen.browser';     // TODO: confirm Tizen component
}

class RemoteScreen extends ConsumerWidget {
  final SamsungDevice device;
  final VoidCallback onSwitch;

  const RemoteScreen({
    super.key,
    required this.device,
    required this.onSwitch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(remoteProvider(device.ip));
    final notifier = ref.read(remoteProvider(device.ip).notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
        actions: [
          IconButton(icon: const Icon(Icons.tv), onPressed: onSwitch),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _statusBanner(state.status) ??
            _remoteBody(context, notifier),
      ),
    );
  }

  Widget? _statusBanner(SamsungStatus status) {
    if (status == SamsungStatus.connected) return null;
    final msg = switch (status) {
      SamsungStatus.connecting => 'Connecting…',
      SamsungStatus.authenticating => 'Waiting for TV approval…',
      SamsungStatus.error => 'Connection error',
      _ => 'Disconnected',
    };
    return Center(child: Text(msg));
  }

  Widget _remoteBody(BuildContext context, RemoteNotifier notifier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          // D-Pad
          _DPad(onKey: notifier.sendKey),
          const SizedBox(height: 24),
          // TODO: volume, channel, playback, app launcher sections
          const Text('Remote coming soon', style: TextStyle(color: Color(0xFF585B70))),
        ],
      ),
    );
  }
}

class _DPad extends StatelessWidget {
  final Future<void> Function(String) onKey;

  const _DPad({required this.onKey});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RemoteButton(icon: Icons.keyboard_arrow_up, onPressed: () => onKey(SamsungKey.up)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RemoteButton(icon: Icons.keyboard_arrow_left, onPressed: () => onKey(SamsungKey.left)),
            const SizedBox(width: 8),
            RemoteButton(label: 'OK', onPressed: () => onKey(SamsungKey.enter)),
            const SizedBox(width: 8),
            RemoteButton(icon: Icons.keyboard_arrow_right, onPressed: () => onKey(SamsungKey.right)),
          ],
        ),
        RemoteButton(icon: Icons.keyboard_arrow_down, onPressed: () => onKey(SamsungKey.down)),
      ],
    );
  }
}
