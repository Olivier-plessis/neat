import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/core/app_info/app_version_provider.dart';
import 'package:neat/core/theme/app_theme.dart';
import 'package:neat/features/identity/presentation/screens/main_layout.dart';

class SplashScreen extends HookConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glowCtrl = useAnimationController(
      duration: const Duration(milliseconds: 1600),
    );
    final contentCtrl = useAnimationController(
      duration: const Duration(milliseconds: 700),
    );
    final pulseCtrl = useAnimationController(
      duration: const Duration(milliseconds: 2000),
    );

    useEffect(() {
      glowCtrl.forward();
      Future.delayed(const Duration(milliseconds: 500), contentCtrl.forward);
      Future.delayed(
        const Duration(milliseconds: 900),
        () => pulseCtrl.repeat(reverse: true),
      );

      final timer = Timer(const Duration(milliseconds: 2800), () {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder<void>(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (_, _, _) => const MainLayout(),
            transitionsBuilder: (_, anim, _, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
      });

      return timer.cancel;
    }, []);

    final glowFade = CurvedAnimation(parent: glowCtrl, curve: Curves.easeOut);
    final glowScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: glowCtrl, curve: Curves.easeOutCubic),
    );
    final contentFade =
        CurvedAnimation(parent: contentCtrl, curve: Curves.easeOut);
    final pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: pulseCtrl, curve: Curves.easeInOut),
    );

    return Scaffold(
      backgroundColor: AppTheme.colorNeutralBg,
      body: Stack(
        children: [
          // Dot grid background
          const Positioned.fill(child: _DotGrid()),

          // Centered logo + text
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: Listenable.merge([glowCtrl, pulseCtrl]),
                  builder: (context, _) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer soft glow — pulsing
                        Opacity(
                          opacity: glowFade.value,
                          child: Transform.scale(
                            scale: glowScale.value * pulse.value * 1.4,
                            child: Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppTheme.colorPrimaryCyan.withValues(alpha: 0.12),
                                    AppTheme.colorPrimaryCyan.withValues(alpha: 0.04),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Inner glow — tighter, brighter
                        Opacity(
                          opacity: glowFade.value,
                          child: Transform.scale(
                            scale: glowScale.value * pulse.value,
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppTheme.colorPrimaryCyan.withValues(alpha: 0.25),
                                    AppTheme.colorPrimaryCyan.withValues(alpha: 0.08),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Logo
                        FadeTransition(
                          opacity: contentFade,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: AppTheme.colorPrimaryCyan.withValues(alpha: 0.25),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(21),
                              child: Image.asset(
                                'assets/images/neat_logo.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 28),

                // NEAT wordmark
                FadeTransition(
                  opacity: contentFade,
                  child: const Text(
                    'N E A T',
                    style: TextStyle(
                      color: AppTheme.colorPrimaryCyan,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 10,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Version badge
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: contentFade,
              child: Text(
                ref.watch(appVersionProvider).maybeWhen(
                      data: (v) => v,
                      orElse: () => '',
                    ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white24,
                  fontSize: 11,
                  letterSpacing: 3,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dot grid background ────────────────────────────────────────────────────────

class _DotGrid extends StatelessWidget {
  const _DotGrid();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DotGridPainter());
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..style = PaintingStyle.fill;

    const spacing = 24.0;
    const radius = 1.2;

    final cols = (size.width / spacing).ceil();
    final rows = (size.height / spacing).ceil();

    for (var r = 0; r <= rows; r++) {
      for (var c = 0; c <= cols; c++) {
        canvas.drawCircle(
          Offset(c * spacing, r * spacing),
          radius,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
