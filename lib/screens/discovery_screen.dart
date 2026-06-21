import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/saved_device.dart';
import '../models/samsung_device.dart';
import '../providers/saved_devices_provider.dart';
import 'remote_screen.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  final _ipController = TextEditingController();

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  void _connect(String ip) {
    final trimmed = ip.trim();
    if (trimmed.isEmpty) return;
    final device = SamsungDevice(ip: trimmed, name: 'Samsung TV');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RemoteScreen(
          device: device,
          onSwitch: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(savedDevicesProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('DPad Nova')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (saved.isNotEmpty) ...[
            Text('Saved TVs', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontSize: 12)),
            const SizedBox(height: 8),
            ...saved.map((d) => ListTile(
                  title: Text(d.name),
                  subtitle: Text(d.ip),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _connect(d.ip),
                )),
            const Divider(height: 32),
          ],
          Text('Connect by IP', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontSize: 12)),
          const SizedBox(height: 8),
          TextField(
            controller: _ipController,
            decoration: const InputDecoration(
              hintText: '192.168.1.x',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onSubmitted: _connect,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => _connect(_ipController.text),
            child: const Text('Connect'),
          ),
          const SizedBox(height: 24),
          Text(
            'Enable ADB debugging on your Samsung TV:\nSettings → General → External Device Manager → Device Connect Manager → Access Notification',
            style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4), height: 1.5),
          ),
        ],
      ),
    );
  }
}
