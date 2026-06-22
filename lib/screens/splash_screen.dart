import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/samsung_device.dart';
import '../providers/saved_devices_provider.dart';
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

  // Devices are pre-loaded in main() and already in the provider.
  // We just wait for the splash duration then navigate.
  Future<void> _run() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    final saved = ref.read(savedDevicesProvider);
    _navigate(saved.length == 1 ? saved.first.ip : null,
        saved.length == 1 ? saved.first.name : null);
  }

  void _navigate(String? singleIp, String? singleName) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (ctx) {
          if (singleIp != null && singleName != null) {
            final device = SamsungDevice(ip: singleIp, name: singleName);
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
