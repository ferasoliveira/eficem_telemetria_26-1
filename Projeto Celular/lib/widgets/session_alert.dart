import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Full-screen overlay alert shown when a session/lap change is detected.
///
/// Triggered by the ESP32 button press — appears for ~3 seconds
/// with a pulse animation and lap change notification.
class SessionAlert extends StatefulWidget {
  const SessionAlert({super.key});

  @override
  State<SessionAlert> createState() => _SessionAlertState();
}

class _SessionAlertState extends State<SessionAlert>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
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
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Container(
            color: AppTheme.warning.withOpacity(0.15),
            child: Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.warning, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.warning.withOpacity(0.3),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flag_rounded,
                        size: 48,
                        color: AppTheme.warning,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'NOVA VOLTA',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.warning,
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
