import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/samsung_device.dart';
import '../models/saved_device.dart';
import '../providers/discovery_provider.dart';
import '../providers/saved_devices_provider.dart';
import 'remote_screen.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  final _ipController = TextEditingController();
  bool _probing = false;

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  void _connectTo(SamsungDevice device) {
    ref.read(savedDevicesProvider.notifier).updateLastSeen(device.ip);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RemoteScreen(device: device)),
    );
  }

  void _connectSaved(SavedDevice saved) =>
      _connectTo(SamsungDevice(ip: saved.ip, name: saved.name));

  // Manual IP: REST probe first to confirm Samsung TV and get friendly name.
  Future<void> _connectManual() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) return;

    setState(() => _probing = true);
    final device = await ref.read(discoveryProvider.notifier).probe(ip);
    if (!mounted) return;
    setState(() => _probing = false);

    if (device == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No Samsung TV found at $ip'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    _connectTo(device);
  }

  // ── Save sheet ───────────────────────────────────────

  void _showSaveSheet(BuildContext ctx, {required String ip, required String suggestedName}) {
    final ctrl = TextEditingController(text: suggestedName);
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20, 20, 20,
          MediaQuery.of(sheetCtx).viewInsets.bottom + 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Save TV',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _commitSave(sheetCtx, ctrl, ip),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _commitSave(sheetCtx, ctrl, ip),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _commitSave(BuildContext sheetCtx, TextEditingController ctrl, String ip) {
    final name = ctrl.text.trim();
    ref.read(savedDevicesProvider.notifier).add(SavedDevice(
          ip: ip,
          name: name.isEmpty ? ip : name,
          lastSeen: DateTime.now(),
        ));
    Navigator.pop(sheetCtx);
  }

  // ── Rename dialog ────────────────────────────────────

  void _showRenameDialog(BuildContext ctx, SavedDevice device) {
    final ctrl = TextEditingController(text: device.name);
    showDialog<void>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Rename TV'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                ref.read(savedDevicesProvider.notifier).rename(device.ip, name);
              }
              Navigator.pop(dialogCtx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ── Delete confirmation ──────────────────────────────

  void _confirmDelete(BuildContext ctx, SavedDevice device) {
    showDialog<void>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Remove saved TV?'),
        content: Text('Remove "${device.name}" from your saved TVs?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(savedDevicesProvider.notifier).remove(device.ip);
              Navigator.pop(dialogCtx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final discovered = ref.watch(discoveryProvider);
    final notifier = ref.read(discoveryProvider.notifier);
    final savedDevices = ref.watch(savedDevicesProvider);
    final scanning = discovered.isScanning;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DPad Nova'),
        actions: [
          if (scanning)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Scan for TVs',
              onPressed: notifier.scan,
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Saved TVs ──
          if (savedDevices.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'SAVED',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ),
            for (final d in savedDevices)
              ListTile(
                leading: const Icon(Icons.tv),
                title: Text(d.name),
                subtitle: Text(
                  d.ip,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: 'Rename',
                      onPressed: () => _showRenameDialog(context, d),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: Colors.redAccent),
                      tooltip: 'Remove',
                      onPressed: () => _confirmDelete(context, d),
                    ),
                  ],
                ),
                onTap: () => _connectSaved(d),
              ),
            const Divider(height: 1),
          ],

          // ── mDNS scan results (deduped) ──
          Expanded(
            child: discovered.devices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tv_off,
                            size: 64,
                            color: cs.onSurface.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        Text(
                          scanning
                              ? 'Scanning network…'
                              : discovered.devices.isEmpty &&
                                      !scanning
                                  ? 'Tap search to find TVs'
                                  : 'No TVs found',
                          style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  )
                : Builder(builder: (ctx) {
                    final unsaved = discovered.devices
                        .where((d) => !savedDevices.any((s) => s.ip == d.ip))
                        .toList();
                    if (unsaved.isEmpty) {
                      return Center(
                        child: Text(
                          'No new TVs found',
                          style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.5)),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: unsaved.length,
                      itemBuilder: (_, i) {
                        final tv = unsaved[i];
                        return ListTile(
                          leading: const Icon(Icons.tv),
                          title: Text(tv.name),
                          subtitle: Text(
                            tv.ip,
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.bookmark_border, size: 20),
                                tooltip: 'Save TV',
                                onPressed: () => _showSaveSheet(
                                  context,
                                  ip: tv.ip,
                                  suggestedName: tv.name,
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap: () => _connectTo(tv),
                        );
                      },
                    );
                  }),
          ),

          const Divider(height: 1),

          // ── Manual IP entry ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Manual IP',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ipController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          hintText: '192.168.1.x',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        onSubmitted: (_) => _connectManual(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.bookmark_border),
                      tooltip: 'Save TV',
                      onPressed: () {
                        final ip = _ipController.text.trim();
                        if (ip.isEmpty) return;
                        _showSaveSheet(context, ip: ip, suggestedName: ip);
                      },
                    ),
                    const SizedBox(width: 4),
                    if (_probing)
                      const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      FilledButton(
                        onPressed: _connectManual,
                        child: const Text('Connect'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
