import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../core/theme/app_theme.dart';
import '../core/constants.dart';

/// Large speed gauge widget with animated arc and digital readout.
///
/// Occupies the left half of the landscape dashboard.
/// Cyan accent color for the speed arc.
class SpeedGauge extends StatelessWidget {
  final double speed;
  final bool isActive;

  /// Maximum speed for the gauge arc (km/h).
  static const double maxSpeed = 50.0;

  const SpeedGauge({
    super.key,
    required this.speed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final clampedSpeed = speed.clamp(0.0, maxSpeed);
    final fraction = clampedSpeed / maxSpeed;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Label
          Text(
            'VELOCIDADE',
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
                final size = math.min(constraints.maxWidth, constraints.maxHeight);
                return Center(
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: CustomPaint(
                      painter: _ArcPainter(
                        fraction: fraction,
                        activeColor: AppTheme.primary,
                        isActive: isActive,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: size * 0.30,
                                fontWeight: FontWeight.w700,
                                color: isActive
                                    ? AppTheme.textPrimary
                                    : AppTheme.textMuted,
                                height: 1.0,
                              ),
                              child: Text(speed.toStringAsFixed(1)),
                            ),
                            Text(
                              AppConstants.speedUnit,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: size * 0.07,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondary,
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

/// Custom arc painter for gauge widgets.
class _ArcPainter extends CustomPainter {
  final double fraction;
  final Color activeColor;
  final bool isActive;

  _ArcPainter({
    required this.fraction,
    required this.activeColor,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 16;
    const startAngle = 0.75 * math.pi; // 135 degrees
    const sweepTotal = 1.5 * math.pi;  // 270 degrees arc

    // Background arc (dark)
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

    // Active arc (colored)
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

      // Glow effect when active
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
  bool shouldRepaint(_ArcPainter old) =>
      old.fraction != fraction || old.isActive != isActive;
}
