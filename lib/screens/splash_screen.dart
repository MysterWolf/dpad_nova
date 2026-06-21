import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/saved_device.dart';
import '../models/samsung_device.dart';
import '../providers/saved_devices_provider.dart';
import '../services/saved_devices_service.dart';
import 'discovery_screen.dart';
import 'remote_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    List<SavedDevice> saved = [];
    await Future.wait([
      Future.delayed(const Duration(seconds: 3)),
      () async { saved = await SavedDevicesService().load(); }(),
    ]);
    if (!mounted) return;
    ref.read(savedDevicesProvider.notifier).init(saved);
    _navigate(saved);
  }

  void _navigate(List<SavedDevice> saved) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (ctx) {
          if (saved.length == 1) {
            final d = saved.first;
            final device = SamsungDevice(ip: d.ip, name: d.name);
            return RemoteScreen(
              device: device,
              onSwitch: () => Navigator.of(ctx).pushReplacement(
                MaterialPageRoute(builder: (_) => const DiscoveryScreen()),
              ),
            );
          }
          return const DiscoveryScreen();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/mws_mark_dark.png', width: 120, height: 120),
            const SizedBox(height: 20),
            const Text(
              'mysterwolf',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 26,
                fontWeight: FontWeight.w400,
                color: Color(0xFFCDD6F4),
                letterSpacing: 2.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'studios',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF6C7086),
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 36),
            const Text(
              'A simple Samsung TV remote.\nNo ads, no subscriptions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF585B70),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
