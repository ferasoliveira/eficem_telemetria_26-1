import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../providers/telemetry_provider.dart';
import '../services/ble_service.dart';
import '../services/mqtt_service.dart';
import '../widgets/speed_gauge.dart';
import '../widgets/power_gauge.dart';
import '../widgets/connection_status_bar.dart';
import '../widgets/session_alert.dart';

/// Main dashboard screen — the pilot's primary interface.
///
/// Layout (Landscape):
/// ┌─────────────────────────────────────────────────────┐
/// │  [BLE ●]  [MQTT ●]          VOLTA 1          [···]  │
/// ├────────────────────────┬────────────────────────────┤
/// │                        │                            │
/// │     SPEED GAUGE        │       POWER GAUGE          │
/// │      42.3 km/h         │        127.4 W             │
/// │                        │                            │
/// ├────────────────────────┴────────────────────────────┤
/// │  ⚡ 0.82 Wh  │  📏 1.23 km  │  🔋 48.2V  2.65A    │
/// └─────────────────────────────────────────────────────┘
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Start BLE connection on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(telemetryProvider.notifier).startConnection();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(telemetryProvider);
    final packet = state.packet;

    return Scaffold(
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Top bar: connection indicators + session counter
                ConnectionStatusBar(
                  bleState: state.bleState,
                  mqttState: state.mqttState,
                  sessionNumber: packet.sessionNumber,
                  isReceiving: state.isReceiving,
                  onSettingsTap: () => _showSettingsDialog(context),
                ),

                // Main gauges area
                Expanded(
                  child: Row(
                    children: [
                      // Speed gauge (left half)
                      Expanded(
                        child: SpeedGauge(
                          speed: packet.speedKmh,
                          isActive: state.isReceiving,
                        ),
                      ),

                      // Vertical divider
                      Container(
                        width: 1,
                        margin: const EdgeInsets.symmetric(vertical: 24),
                        color: AppTheme.border,
                      ),

                      // Power gauge (right half)
                      Expanded(
                        child: PowerGauge(
                          power: packet.powerW,
                          avgPower: packet.avgPowerW,
                          isActive: state.isReceiving,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom info bar
                _buildInfoBar(packet),
              ],
            ),
          ),

          // Session change alert overlay
          if (state.sessionJustChanged)
            const SessionAlert(),
        ],
      ),
    );
  }

  /// Bottom bar with secondary metrics.
  Widget _buildInfoBar(packet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _infoItem('⚡', '${packet.energyWh.toStringAsFixed(2)} Wh',
              AppTheme.secondary),
          _divider(),
          _infoItem('📏', '${(packet.distanceM / 1000).toStringAsFixed(2)} km',
              AppTheme.primary),
          _divider(),
          _infoItem('🔋', '${packet.batteryV.toStringAsFixed(1)}V',
              AppTheme.warning),
          _infoItem('', '${packet.currentA.toStringAsFixed(2)}A',
              AppTheme.warning),
        ],
      ),
    );
  }

  Widget _infoItem(String icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon.isNotEmpty)
          Text(icon, style: const TextStyle(fontSize: 16)),
        if (icon.isNotEmpty) const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 20,
      color: AppTheme.border,
    );
  }

  /// Settings dialog for MQTT broker IP.
  void _showSettingsDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Configurações'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'IP do Notebook (MQTT Broker)',
                hintText: '192.168.1.100',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref
                    .read(telemetryProvider.notifier)
                    .connectMqtt(controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Conectar'),
          ),
        ],
      ),
    );
  }
}
