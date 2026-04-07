import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../services/ble_service.dart';
import '../services/mqtt_service.dart';

/// Top status bar showing BLE and MQTT connection indicators,
/// session/lap counter, and settings button.
class ConnectionStatusBar extends StatelessWidget {
  final BleConnectionState bleState;
  final MqttConnectionState mqttState;
  final int sessionNumber;
  final bool isReceiving;
  final VoidCallback? onSettingsTap;

  const ConnectionStatusBar({
    super.key,
    required this.bleState,
    required this.mqttState,
    required this.sessionNumber,
    this.isReceiving = false,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: Row(
        children: [
          // BLE status
          _StatusChip(
            label: 'BLE',
            color: _bleColor(),
            isAnimating: bleState == BleConnectionState.scanning ||
                bleState == BleConnectionState.connecting,
          ),
          const SizedBox(width: 12),

          // MQTT status
          _StatusChip(
            label: 'MQTT',
            color: _mqttColor(),
            isAnimating: mqttState == MqttConnectionState.connecting,
          ),
          const SizedBox(width: 12),

          // Data receiving indicator
          if (isReceiving)
            _StatusChip(
              label: 'DADOS',
              color: AppTheme.secondary,
              isAnimating: true,
            ),

          const Spacer(),

          // Session/Lap counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: Text(
              'VOLTA $sessionNumber',
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
                letterSpacing: 2,
              ),
            ),
          ),

          const Spacer(),

          // Settings button
          IconButton(
            onPressed: onSettingsTap,
            icon: const Icon(Icons.settings_outlined, size: 22),
            color: AppTheme.textMuted,
          ),
        ],
      ),
    );
  }

  Color _bleColor() {
    switch (bleState) {
      case BleConnectionState.connected:
        return AppTheme.secondary;
      case BleConnectionState.scanning:
      case BleConnectionState.connecting:
        return AppTheme.warning;
      case BleConnectionState.error:
        return AppTheme.danger;
      case BleConnectionState.disconnected:
        return AppTheme.textMuted;
    }
  }

  Color _mqttColor() {
    switch (mqttState) {
      case MqttConnectionState.connected:
        return AppTheme.secondary;
      case MqttConnectionState.connecting:
        return AppTheme.warning;
      case MqttConnectionState.error:
        return AppTheme.danger;
      case MqttConnectionState.disconnected:
        return AppTheme.textMuted;
    }
  }
}

/// Small status indicator chip with optional pulsing animation.
class _StatusChip extends StatefulWidget {
  final String label;
  final Color color;
  final bool isAnimating;

  const _StatusChip({
    required this.label,
    required this.color,
    this.isAnimating = false,
  });

  @override
  State<_StatusChip> createState() => _StatusChipState();
}

class _StatusChipState extends State<_StatusChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isAnimating) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_StatusChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isAnimating && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = widget.isAnimating
            ? 0.4 + (_controller.value * 0.6)
            : 1.0;
        return Opacity(
          opacity: opacity,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.color,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
