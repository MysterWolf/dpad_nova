import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/saved_devices_provider.dart';
import 'services/saved_devices_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Pre-load saved devices before first frame so the provider starts with
  // the correct list — no empty-list flash on the discovery/remote screen.
  final initialDevices = await SavedDevicesService().load();

  runApp(
    ProviderScope(
      overrides: [
        savedDevicesProvider.overrideWith(
          (ref) => SavedDevicesNotifier(
            SavedDevicesService(),
            initial: initialDevices,
          ),
        ),
      ],
      child: const DPadNovaApp(),
    ),
  );
}

class DPadNovaApp extends StatelessWidget {
  const DPadNovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DPad Nova',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7B82FF),
          brightness: Brightness.dark,
        ).copyWith(
          surface: const Color(0xFF1E1E2E),
          onSurface: const Color(0xFFCDD6F4),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0F1A),
          foregroundColor: Color(0xFFCDD6F4),
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
