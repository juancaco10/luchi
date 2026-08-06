import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/firefly_colors.dart';
import '../../../core/utils/constants.dart';
import '../../../widgets/firefly_background.dart';
import '../../auth/providers/auth_provider.dart';

/// Pantalla de "lobby" antes de entrar al juego (quiz Kahoot).
/// Muestra bg_play de fondo, luciérnagas flotantes, logo, título
/// "Explorador Nocturno" y un botón central animado (btn_play) con
/// efecto de respiración (escala sutil cíclica).
class PlayLobbyScreen extends ConsumerWidget {
  const PlayLobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── 1. Background image (bg_play) ─────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_play.png',
              fit: BoxFit.cover,
            ),
          ),

          // ── 2. Gradient overlay for depth ─────────────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.4),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // ── 3. Fireflies (behind button, in front of bg) ──────
          const FireflyBackground(count: 18, intensity: 0.55),

          // ── 4. Content layer ──────────────────────────────────
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  // ── Top bar: logo left ────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16, top: 12, right: 16,
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/logo_luchi.png',
                          height: 44,
                        ),
                        const Spacer(),
                        // Level badge (compact)
                        if (user != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: context.colors.primary
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shield_rounded,
                                  color: context.colors.primary,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Nv. ${user.level}',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: context.colors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),

                  // ── Title: "Explorador Nocturno" ──────────────
                  Text(
                    'Explorador',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          color: context.colors.primary
                              .withValues(alpha: 0.6),
                          blurRadius: 24,
                        ),
                        const Shadow(
                          color: Colors.black54,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Nocturno',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: context.colors.primary,
                      letterSpacing: 3,
                      shadows: [
                        Shadow(
                          color: context.colors.primary
                              .withValues(alpha: 0.5),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Play button (btn_play) with breathing anim ─
                  _BreathingPlayButton(
                    size: size.width * 0.48,
                    onTap: () {
                      context.go('/game/level-1');
                    },
                  ),

                  const Spacer(flex: 2),

                  // ── Bottom info strip ─────────────────────────
                  if (user != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _InfoChip(
                              icon: Icons.star_rounded,
                              label: '${user.points} pts',
                              color: context.firefly.glow,
                            ),
                            Container(
                              width: 1,
                              height: 28,
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                            _InfoChip(
                              icon: Icons.emoji_events_rounded,
                              label: AppConstants.getLevelName(user.points),
                              color: context.colors.primary,
                            ),
                            Container(
                              width: 1,
                              height: 28,
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                            _InfoChip(
                              icon: Icons.local_fire_department_rounded,
                              label: 'Nv. ${user.level}',
                              color: context.firefly.warning,
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Breathing play button ─────────────────────────────────────────────
//
// Efecto: el botón hace un ciclo sutil de escala 1.0 → 1.06 → 1.0 de
// forma continua (como si "respirara"), dando la sensación de movimiento
// sin ser molesto. Se implementa con un AnimationController en loop.

class _BreathingPlayButton extends StatefulWidget {
  const _BreathingPlayButton({
    required this.size,
    required this.onTap,
  });

  final double size;
  final VoidCallback onTap;

  @override
  State<_BreathingPlayButton> createState() => _BreathingPlayButtonState();
}

class _BreathingPlayButtonState extends State<_BreathingPlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: child,
          );
        },
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: context.colors.primary.withValues(alpha: 0.35),
                blurRadius: 40,
                spreadRadius: 8,
              ),
              BoxShadow(
                color: context.firefly.glow.withValues(alpha: 0.2),
                blurRadius: 60,
                spreadRadius: 12,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/btn_play.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Small info chip used in the bottom strip ──────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}
