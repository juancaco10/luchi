import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fireflyController;
  final List<_FireflyParticle> _fireflies = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _fireflyController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Generate 18 firefly particles
    for (int i = 0; i < 18; i++) {
      _fireflies.add(_FireflyParticle.random(_random));
    }

    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 3200));
    if (!mounted) return;

    if (!LocalStorage.instance.onboardingDone) {
      context.go('/onboarding');
    } else if (LocalStorage.instance.isLoggedIn) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _fireflyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Starry background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF060A12),
                  Color(0xFF0B0F1A),
                  Color(0xFF0E1525),
                ],
              ),
            ),
          ),

          // Floating firefly particles
          AnimatedBuilder(
            animation: _fireflyController,
            builder: (context, _) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _FireflyPainter(
                  _fireflies,
                  _fireflyController.value,
                ),
              );
            },
          ),

          // Perfectly centered responsive content column
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo glow container
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(34),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.5),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                            BoxShadow(
                              color: AppColors.secondary.withOpacity(0.3),
                              blurRadius: 70,
                              spreadRadius: 15,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(34),
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => const Icon(
                              Icons.local_fire_department_rounded,
                              size: 80,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .scale(
                            duration: 800.ms,
                            curve: Curves.elasticOut,
                            begin: const Offset(0.4, 0.4),
                            end: const Offset(1.0, 1.0),
                          )
                          .fadeIn(duration: 600.ms),

                      const SizedBox(height: 24),

                      // App name
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppColors.primaryGradient.createShader(bounds),
                        child: const Text(
                          'Luchi',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      )
                          .animate(delay: 400.ms)
                          .fadeIn(duration: 700.ms)
                          .slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 32),

                      // Animated Loading Dots
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (i) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                          )
                              .animate(
                                delay: Duration(milliseconds: 700 + (i * 150)),
                                onPlay: (c) => c.repeat(reverse: true),
                              )
                              .fadeIn(duration: 300.ms)
                              .scale(
                                begin: const Offset(0.5, 0.5),
                                end: const Offset(1.2, 1.2),
                                duration: 600.ms,
                                curve: Curves.easeInOut,
                              );
                        }),
                      ),

                      const SizedBox(height: 36),

                      // Tagline
                      const Text(
                        'Protegemos la magia de la noche 🌙',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      )
                          .animate(delay: 900.ms)
                          .fadeIn(duration: 800.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Firefly Particle System ───────────────────────────────────────

class _FireflyParticle {
  double x, y, size, speed, phase, opacity;

  _FireflyParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
    required this.opacity,
  });

  factory _FireflyParticle.random(Random rnd) {
    return _FireflyParticle(
      x: rnd.nextDouble(),
      y: rnd.nextDouble(),
      size: 2.0 + rnd.nextDouble() * 4.0,
      speed: 0.3 + rnd.nextDouble() * 0.7,
      phase: rnd.nextDouble() * 2 * pi,
      opacity: 0.4 + rnd.nextDouble() * 0.6,
    );
  }
}

class _FireflyPainter extends CustomPainter {
  final List<_FireflyParticle> fireflies;
  final double t;

  _FireflyPainter(this.fireflies, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final ff in fireflies) {
      final progress = (t * ff.speed + ff.phase) % 1.0;
      final flicker = (sin(progress * 2 * pi * 3) + 1) / 2;
      final alpha = (ff.opacity * flicker * 255).toInt().clamp(0, 255);

      final cx = ff.x * size.width + sin(progress * 2 * pi) * 20;
      final cy = ff.y * size.height - progress * size.height * 0.3;
      final cy2 = cy < 0 ? cy + size.height : cy;

      final paint = Paint()
        ..color = Color.fromARGB(alpha, 245, 208, 32)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, ff.size * 1.5);

      canvas.drawCircle(Offset(cx, cy2), ff.size, paint);
    }
  }

  @override
  bool shouldRepaint(_FireflyPainter old) => true;
}
