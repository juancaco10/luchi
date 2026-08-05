import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/firefly_colors.dart';

class HomeHeader extends ConsumerWidget {
  final String userName;
  final bool isSmallScreen;

  const HomeHeader({
    super.key,
    required this.userName,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeProvider); // rebuild al cambiar de tema

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo
            Image.asset(
              'assets/images/logo_luchi.png',
              height: isSmallScreen ? 55 : 75,
              errorBuilder: (c, e, s) => Text(
                'Luchi 🪲',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: context.colors.primary,
                ),
              ),
            ),

            // Actions Right
            Row(
              children: [

                _iconButton(context, Icons.notifications_none_rounded, semanticLabel: 'Notificaciones'),
                const SizedBox(width: 8),

                // Avatar
                Semantics(
                  button: true,
                  label: 'Ir a tu perfil',
                  child: GestureDetector(
                    onTap: () => context.go('/profile'),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: context.colors.primary, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: context.isDark
                                ? context.colors.primary.withValues(alpha: 0.3)
                                : Colors.black12,
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/images/avatar_mateo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => CircleAvatar(
                            backgroundColor: context.firefly.cardSurface,
                            child: const Text('👦', style: TextStyle(fontSize: 20)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Welcome Text
        Text(
          '¡Hola, $userName! 👋',
          style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),

        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: context.colors.primary.withValues(alpha: context.isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.isDark
                  ? context.colors.primary.withValues(alpha: 0.4)
                  : Colors.black54, // Borde negro/oscuro en modo claro
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🛡️', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 6),
              Text(
                'Explorador Nocturno',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: context.isDark ? context.colors.primary : Colors.black87, // Letras negras en modo claro
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.15, end: 0);
  }

  Widget _iconButton(
    BuildContext context,
    IconData icon, {
    required String semanticLabel,
    VoidCallback? onTap,
  }) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              if (!context.isDark)
                const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Icon(icon, color: context.colors.onSurface, size: 20),
        ),
      ),
    );
  }
}
