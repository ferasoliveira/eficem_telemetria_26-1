import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'core/theme/app_theme.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Force landscape orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Fullscreen immersive mode (no status bar, no navigation bar)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Keep screen on while app is running
  WakelockPlus.enable();

  runApp(const ProviderScope(child: EficemPilotApp()));
}

class EficemPilotApp extends StatelessWidget {
  const EficemPilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EFICEM Pilot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const DashboardScreen(),
    );
  }
}
