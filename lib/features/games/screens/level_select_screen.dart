import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/firefly_colors.dart';
import '../../../core/utils/constants.dart';
import '../../../widgets/firefly_background.dart';
import '../data/game_catalog.dart';
import '../models/game_id.dart';
import '../providers/games_progress_provider.dart';
import '../widgets/star_row.dart';

/// Cuadrícula de 10 niveles para un juego. Ruta `/game/:gameId`.
///
/// Sustituye a la navegación directa hub → nivel único que tenía el
/// prototipo: ahora cada juego tiene su propia progresión de 10 niveles con
/// desbloqueo secuencial y estrellas visibles antes de entrar.
class LevelSelectScreen extends ConsumerWidget {
  const LevelSelectScreen({super.key, required this.gameId});

  final GameId gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = GameCatalog.info(gameId);
    final levels = GameCatalog.levels(gameId);
    final progress = ref.watch(gameProgressProvider(gameId));

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              '${AppConstants.assetsImages}bg_game.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  FireflyBackground(
                count: 16,
                intensity: context.isDark ? 0.5 : 0.3,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_rounded,
                            color: context.colors.primary),
                        onPressed: () => context.pop(),
                      ),
                      Icon(info.icon, color: info.accent, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          info.title,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: context.colors.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: context.firefly.cardSurface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Colors.amber, size: 15),
                            const SizedBox(width: 3),
                            Text(
                              '${progress.totalStars}/${progress.maxStars}',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: context.colors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    info.description,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      color: context.colors.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 18,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: levels.length,
                        itemBuilder: (context, i) {
                          final level = levels[i].level;
                          return _LevelNode(
                            level: level,
                            stars: progress.starsFor(level),
                            unlocked: progress.isUnlocked(level),
                            onTap: () => context
                                .push('/game/${gameId.slug}/play/$level'),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({
    required this.level,
    required this.stars,
    required this.unlocked,
    required this.onTap,
  });

  final int level;
  final int stars;
  final bool unlocked;
  final VoidCallback onTap;

  /// Contorno oscuro para que el número amarillo resalte sobre el fondo
  /// dorado de la tarjeta desbloqueada.
  static const Color _darkOutlineColor = Color(0x99000000);

  static const List<Shadow> _darkOutline = [
    Shadow(color: _darkOutlineColor, offset: Offset(1.4, 1.4)),
    Shadow(color: _darkOutlineColor, offset: Offset(-1.4, 1.4)),
    Shadow(color: _darkOutlineColor, offset: Offset(1.4, -1.4)),
    Shadow(color: _darkOutlineColor, offset: Offset(-1.4, -1.4)),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: unlocked
            ? onTap
            : () => ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(const SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text('Supera el nivel anterior para abrir este.'),
              )),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: unlocked
                ? context.colors.primary.withValues(alpha: 0.32)
                : context.firefly.cardSurface.withValues(alpha: 0.8),
            border: Border.all(
              color: unlocked
                  ? context.colors.primary.withValues(alpha: 0.95)
                  : context.firefly.cardBorder.withValues(alpha: 0.5),
              width: unlocked ? 2 : 1,
            ),
            boxShadow: unlocked
                ? [
                    BoxShadow(
                      color: context.colors.primary.withValues(alpha: 0.4),
                      blurRadius: 18,
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!unlocked)
                    Icon(Icons.lock_rounded,
                        color: context.colors.onSurface.withValues(alpha: 0.4),
                        size: 26)
                  else
                    Text(
                      '$level',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: context.colors.primary,
                        shadows: _darkOutline,
                      ),
                    ),
                  const SizedBox(height: 6),
                  StarRow(
                    stars: unlocked ? stars : 0,
                    size: 20,
                    outlineColor: _darkOutlineColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
