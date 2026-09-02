import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/firefly_colors.dart';
import '../../../features/profile/utils/avatar_image.dart';

class HomeHeader extends ConsumerWidget {
  final String userName;
  final bool isSmallScreen;
  final String? avatarUrl;

  const HomeHeader({
    super.key,
    required this.userName,
    required this.isSmallScreen,
    this.avatarUrl,
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

                // Antes vivía dentro del perfil (había que entrar ahí
                // primero); se movió aquí para que Ajustes quede a un toque
                // desde el inicio. `push`, no `go`: Ajustes es una ruta
                // fuera del shell y con `go` se reemplaza toda la pila, así
                // que el botón de retroceso de Android cerraba la app en vez
                // de volver al home.
                _iconButton(
                  context,
                  Icons.settings_rounded,
                  semanticLabel: 'Configuración',
                  onTap: () => context.push('/settings'),
                ),
                const SizedBox(width: 8),

                // Avatar
                Semantics(
                  button: true,
                  label: 'Ir a tu perfil',
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () => context.go('/profile'),
                      customBorder: const CircleBorder(),
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
                          child: _buildAvatar(context),
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
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.15, end: 0);
  }

  /// Avatar real del usuario: foto de Google (`http...`) o el avatar
  /// elegido en el perfil (`avatarXX.png`). Si no hay avatar guardado o el
  /// asset/URL falla, cae al avatar por defecto de siempre.
  Widget _buildAvatar(BuildContext context) {
    final image = avatarImageFor(avatarUrl);
    return Image(
      image: image ?? const AssetImage('assets/images/avatar_mateo.png'),
      fit: BoxFit.cover,
      errorBuilder: (c, e, s) => CircleAvatar(
        backgroundColor: context.firefly.cardSurface,
        child: const Text('👦', style: TextStyle(fontSize: 20)),
      ),
    );
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
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
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
      ),
    );
  }
}
