import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/firefly_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/sightings/models/sighting_model.dart';
import '../../../features/sightings/providers/sightings_provider.dart';
import '../../../features/sightings/utils/sighting_format.dart';
import '../../../features/profile/utils/avatar_image.dart';
import 'sighting_details_modal.dart';

class RecentSightings extends ConsumerWidget {
  const RecentSightings({super.key, this.scale = 1.0});

  /// Factor de escala para el alto de la lista — ver ScreenFitter.
  final double scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sightingsProvider);
    final sightings = state.sightings.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF72E26E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Avistamientos recientes',
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            // Antes era un GestureDetector pelado: ~82×18 px de área
            // táctil, sin padding ni feedback — muy por debajo del mínimo
            // de 48×48 de Material y visualmente indistinguible del
            // puntito de estado de al lado (mismo verde). Con Material +
            // InkWell + padding queda claro que es un botón y responde en
            // toda su píldora, no solo en el texto.
            Material(
              color: const Color(0xFF72E26E).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () => context.go('/sightings'),
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ver todos',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF72E26E),
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, color: Color(0xFF72E26E), size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180 * scale,
          child: sightings.isEmpty
              ? _EmptyState(isLoading: state.isLoading)
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: sightings.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => _SightingCard(sighting: sightings[index]),
                ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isLoading;
  const _EmptyState({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }
    return GestureDetector(
      onTap: () => context.go('/sightings/new'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: context.firefly.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.firefly.cardBorder),
        ),
        child: Row(
          children: [
            const Text('✨', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Aún no tienes avistamientos. ¡Registra el primero!',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.text.bodyMedium?.color,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.text.bodyMedium?.color),
          ],
        ),
      ),
    );
  }
}

class _SightingCard extends ConsumerWidget {
  final SightingModel sighting;

  const _SightingCard({required this.sighting});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationFull = sightingLocationLabel(sighting);
    final locationShort = sightingShortLocationLabel(sighting);
    // Foto real del autor: solo para avistamientos propios (la del usuario
    // actual, de Google o el avatar elegido). Lo ajeno del feed se muestra
    // anónimo siempre — nunca la foto de otro niño.
    final user = ref.watch(currentUserProvider);
    final authorImage = sighting.isMine ? avatarImageFor(user?.avatarUrl) : null;

    return GestureDetector(
      onTap: () => SightingDetailsModal.show(context, sighting, locationFull, ref.read(sightingsProvider).sightings.length),
      child: Container(
        width: 135,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: sighting.isPending
                ? context.firefly.warning.withValues(alpha: 0.6)
                : (context.isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05)),
            width: 1,
          ),
          boxShadow: [
            if (!context.isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _SightingPhoto(sighting: sighting),
              // Degradado para que el texto blanco se lea sobre la foto.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.2),
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      stops: const [0.5, 0.75, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_outlined, size: 10, color: Colors.black87),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                locationShort,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (sighting.isPending)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.cloud_upload_outlined, size: 14, color: Colors.white),
                      )
                    else
                      Text(
                        relativeTimeShort(sighting.createdAt),
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Avatar del autor, más grande. Lo propio usa la
                        // foto real del usuario (Google o avatar elegido);
                        // lo ajeno, un icono anónimo.
                        ClipOval(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: authorImage != null
                                ? Image(
                                    image: authorImage,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) =>
                                        const Icon(Icons.person, size: 16),
                                  )
                                : Container(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    child: Icon(
                                      sighting.isMine
                                          ? Icons.person
                                          : Icons.eco_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'x${sighting.quantity}',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                          ),
                        ),
                      ],
                    ),
                    // No se ofrece dar corazón a algo `isPending`: todavía
                    // no existe en el servidor (`toggleLike` fallaría con
                    // un id nulo), así que aquí solo hay hueco vacío hasta
                    // que sincronice.
                    if (!sighting.isPending) _LikeButton(sighting: sighting),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Corazón + contador, en la esquina donde antes había un '✨' decorativo.
/// `GestureDetector` propio para que tocarlo no abra el modal (el de la
/// tarjeta entera) — solo da o quita el corazón.
class _LikeButton extends ConsumerStatefulWidget {
  const _LikeButton({required this.sighting});

  final SightingModel sighting;

  @override
  ConsumerState<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends ConsumerState<_LikeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    lowerBound: 0,
    upperBound: 0.35,
  );

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    if (widget.sighting.id == null) return;
    final wasLiked = widget.sighting.likedByMe;
    if (!wasLiked) {
      // Solo hace el pop al dar corazón, no al quitarlo — el gesto
      // afirmativo se celebra, el negativo no necesita ceremonia.
      _pop.forward(from: 0).then((_) => _pop.reverse());
    }
    await ref.read(sightingsProvider.notifier).toggleLike(widget.sighting.id!);
  }

  @override
  Widget build(BuildContext context) {
    final liked = widget.sighting.likedByMe;
    final count = widget.sighting.likesCount;
    return GestureDetector(
      onTap: _tap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        // Área táctil un poco mayor que el icono visible, sin desplazar el
        // layout — el icono real ya ronda los 14px.
        padding: const EdgeInsets.all(4),
        child: AnimatedBuilder(
          animation: _pop,
          builder: (context, child) => Transform.scale(
            scale: 1 + _pop.value,
            child: child,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                liked ? Icons.favorite : Icons.favorite_border,
                size: 20,
                color: liked ? const Color(0xFFFF5C7A) : Colors.white,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Foto del avistamiento si la hay; si no, un degradado con el emoji de
/// luciérnaga — muchos avistamientos no tendrán foto, la sección es
/// opcional en el formulario.
class _SightingPhoto extends StatelessWidget {
  final SightingModel sighting;
  const _SightingPhoto({required this.sighting});

  @override
  Widget build(BuildContext context) {
    if (sighting.photoUrl == null) return _placeholder(context);

    return Image.network(
      sighting.photoUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _placeholder(context, loading: true),
      errorBuilder: (context, error, stack) => _placeholder(context),
    );
  }

  Widget _placeholder(BuildContext context, {bool loading = false}) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: context.firefly.primaryGradient),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text('✨', style: TextStyle(fontSize: 32)),
      ),
    );
  }
}

