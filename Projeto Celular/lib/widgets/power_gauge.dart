import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../core/theme/app_theme.dart';
import '../core/constants.dart';

/// Power consumption gauge with animated arc and digital readout.
///
/// Occupies the right half of the landscape dashboard.
/// Green accent for normal consumption, amber for high, red for critical.
class PowerGauge extends StatelessWidget {
  final double power;
  final double avgPower;
  final bool isActive;

  /// Maximum power for the gauge arc (Watts).
  static const double maxPower = 500.0;

  /// Threshold for warning color (Watts).
  static const double warningThreshold = 300.0;

  /// Threshold for danger color (Watts).
  static const double dangerThreshold = 400.0;

  const PowerGauge({
    super.key,
    required this.power,
    required this.avgPower,
    this.isActive = false,
  });

  Color _getColor() {
    if (power >= dangerThreshold) return AppTheme.danger;
    if (power >= warningThreshold) return AppTheme.warning;
    return AppTheme.secondary;
  }

  @override
  Widget build(BuildContext context) {
    final clampedPower = power.clamp(0.0, maxPower);
    final fraction = clampedPower / maxPower;
    final color = _getColor();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Label
          Text(
            'CONSUMO',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.textMuted,
                  letterSpacing: 3,
                ),
          ),
          const SizedBox(height: 8),

          // Gauge arc + number
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size =
                    math.min(constraints.maxWidth, constraints.maxHeight);
                return Center(
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: CustomPaint(
                      painter: _PowerArcPainter(
                        fraction: fraction,
                        activeColor: color,
                        isActive: isActive,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Instantaneous power
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: size * 0.28,
                                fontWeight: FontWeight.w700,
                                color: isActive ? color : AppTheme.textMuted,
                                height: 1.0,
                              ),
                              child: Text(power.toStringAsFixed(1)),
                            ),
                            Text(
                              AppConstants.powerUnit,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: size * 0.07,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Average power (smaller, below)
                            Text(
                              'Média: ${avgPower.toStringAsFixed(1)} ${AppConstants.powerUnit}',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: size * 0.055,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Arc painter that changes color based on power level.
class _PowerArcPainter extends CustomPainter {
  final double fraction;
  final Color activeColor;
  final bool isActive;

  _PowerArcPainter({
    required this.fraction,
    required this.activeColor,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 16;
    const startAngle = 0.75 * math.pi;
    const sweepTotal = 1.5 * math.pi;

    // Background arc
    final bgPaint = Paint()
      ..color = AppTheme.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      bgPaint,
    );

    // Active arc
    if (fraction > 0) {
      final activePaint = Paint()
        ..color = isActive ? activeColor : activeColor.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepTotal * fraction,
        false,
        activePaint,
      );

      if (isActive) {
        final glowPaint = Paint()
          ..color = activeColor.withOpacity(0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 24
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepTotal * fraction,
          false,
          glowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PowerArcPainter old) =>
      old.fraction != fraction ||
      old.isActive != isActive ||
      old.activeColor != activeColor;
}
