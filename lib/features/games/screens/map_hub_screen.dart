import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/firefly_colors.dart';
import '../../../widgets/firefly_background.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/game_catalog.dart';
import '../providers/games_progress_provider.dart';

/// Selector de los cinco minijuegos.
///
/// A diferencia del prototipo original, las tarjetas ya no son una lista
/// hardcodeada: se leen de `GameCatalog.games`, y cada una muestra las
/// estrellas totales del jugador y si está bloqueada (`GamesState.isGameUnlocked`).
class MapHubScreen extends ConsumerWidget {
  const MapHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final gamesState = ref.watch(gamesProgressProvider);

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Stack(
        children: [
          FireflyBackground(
            count: 20,
            intensity: context.isDark ? 0.6 : 0.35,
          ),
          SafeArea(
            child: Column(
              children: [
                // Header — pestaña de nivel superior (accesible desde el menú
                // inferior): sin flecha de retroceso, solo el título.
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Text(
                        'Jugar',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: context.colors.onSurface,
                        ),
                      ),
                      const Spacer(),
                      if (user != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.firefly.cardSurface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color:
                                    context.colors.primary.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              // `context.firefly.glow` es un token de sombra/
                              // resplandor (25% alpha) — como color de texto
                              // sólido queda lavado, casi invisible en modo
                              // claro. `context.colors.primary` es el mismo
                              // color pero al 100%, pensado para texto/ícono.
                              Icon(Icons.local_fire_department_rounded,
                                  color: context.colors.primary, size: 16),
                              const SizedBox(width: 4),
                              Text('${user.points}',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.w800,
                                    color: context.colors.primary,
                                  )),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    physics: const BouncingScrollPhysics(),
                    itemCount: GameCatalog.games.length,
                    itemBuilder: (context, index) {
                      final info = GameCatalog.games[index];
                      final progress = gamesState.of(info.id);
                      final unlocked = gamesState.isGameUnlocked(info.id);
                      return _GameCard(
                        info: info,
                        totalStars: progress.totalStars,
                        maxStars: progress.maxStars,
                        unlocked: unlocked,
                      );
                    },
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

class _GameCard extends StatefulWidget {
  const _GameCard({
    required this.info,
    required this.totalStars,
    required this.maxStars,
    required this.unlocked,
  });

  final GameInfo info;
  final int totalStars;
  final int maxStars;
  final bool unlocked;

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
  );
  late final Animation<double> _scale =
      Tween<double>(begin: 1.0, end: 0.95).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
  );
  bool _pressed = false;
  bool _focused = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open() {
    if (!widget.unlocked) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Consigue más estrellas en el juego anterior para desbloquear '
            '"${widget.info.title}".',
          ),
        ),
      );
      return;
    }
    context.push('/game/${widget.info.id.slug}');
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    // FocusableActionDetector añade foco de D-pad/teclado sobre el mismo
    // GestureDetector táctil: ENTER/OK dispara la misma animación de
    // pulsado y el mismo _open() que un tap.
    return FocusableActionDetector(
      onShowFocusHighlight: (focused) => setState(() => _focused = focused),
      actions: {
        ActivateIntent: CallbackAction<Intent>(onInvoke: (_) {
          _open();
          return null;
        }),
      },
      child: GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        setState(() => _pressed = true);
      },
      onTapUp: (_) {
        _controller.reverse();
        setState(() => _pressed = false);
        _open();
      },
      onTapCancel: () {
        _controller.reverse();
        setState(() => _pressed = false);
      },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 24),
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: _focused
                ? Border.all(color: context.firefly.focusRing, width: 3)
                : null,
            boxShadow: [
              BoxShadow(
                color: _pressed
                    ? info.accent.withValues(alpha: 0.5)
                    : Colors.black45,
                blurRadius: _pressed ? 20 : 10,
                spreadRadius: _pressed ? 2 : 0,
                offset: const Offset(0, 8),
              ),
              if (_focused) ...context.firefly.focusShadow,
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  info.cover,
                  fit: BoxFit.cover,
                  color: widget.unlocked ? null : Colors.black,
                  colorBlendMode: widget.unlocked ? null : BlendMode.saturation,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: Colors.grey[900]),
                ),
                // Ligero gradiente en la base para que las estrellas o el candado se lean bien
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: widget.unlocked ? 0.5 : 0.7),
                      ],
                      stops: const [0.6, 1.0],
                    ),
                  ),
                ),
                if (!widget.unlocked)
                  ColoredBox(color: Colors.black.withValues(alpha: 0.25)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!widget.unlocked)
                        const Row(
                          children: [
                            Icon(Icons.lock_rounded, color: Colors.white, size: 24),
                          ],
                        ),
                      if (widget.unlocked)
                        Row(
                          children: [
                            Icon(Icons.star_rounded, color: info.accent, size: 22),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.totalStars} / ${widget.maxStars}',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: info.accent,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black87,
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
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
