import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/firefly_colors.dart';
import '../../../../core/utils/constants.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/sightings/models/sighting_model.dart';
import '../../../features/sightings/providers/sightings_provider.dart';
import '../../../features/sightings/utils/sighting_format.dart';
import '../../../features/sightings/widgets/like_button.dart';
import '../../../features/profile/utils/avatar_image.dart';
import 'sighting_details_modal.dart';

class RecentSightings extends ConsumerStatefulWidget {
  const RecentSightings({super.key, this.scale = 1.0});

  /// Factor de escala para el alto de la lista — ver ScreenFitter.
  final double scale;

  @override
  ConsumerState<RecentSightings> createState() => _RecentSightingsState();
}

class _RecentSightingsState extends ConsumerState<RecentSightings> {
  @override
  void initState() {
    super.initState();
    // Refresco silencioso cada vez que el home vuelve a montar esta
    // sección (entrar a la pestaña, volver de otra pantalla): antes solo
    // se pedía si la lista estaba vacía, así que una vez cargada el feed
    // quedaba congelado el resto de la sesión y los avistamientos de
    // otros usuarios tardaban en aparecer. `silent: true` evita spinner
    // si ya hay datos, y el provider mismo limita la frecuencia
    // (`AppConstants.feedRefreshMinInterval`).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(sightingsProvider.notifier).loadCommunitySightings(silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sightingsProvider);
    final latest = ref.watch(sightingsProvider.notifier).mergedFeed;
    final cards = latest.take(8).toList();

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
                  decoration: BoxDecoration(
                    color: context.colors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Últimas publicaciones',
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
              color: context.colors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                // El mapa muestra los avistamientos de todos; la lista
                // propia se alcanza desde ahí ("Mis avistamientos").
                // /map redirige a /home mientras comunidad está
                // deshabilitada (AppConstants.communityEnabled) — avisar
                // en vez de dejar el tap sin efecto aparente.
                onTap: () {
                  if (!AppConstants.communityEnabled) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(const SnackBar(
                        content: Text(
                            'El mapa comunitario estará disponible próximamente.'),
                      ));
                    return;
                  }
                  context.go('/map');
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ver todos',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w800,
                          color: context.colors.secondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, color: context.colors.secondary, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180 * widget.scale,
          child: cards.isEmpty
              ? _EmptyState(
                  isLoading: state.isLoading || state.isLoadingCommunity,
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: cards.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => _SightingCard(sighting: cards[index]),
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
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
      onTap: () => context.go('/sightings/new'),
      borderRadius: BorderRadius.circular(16),
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
                'Aún no hay avistamientos publicados. ¡Sé el primero!',
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
    // Autor visible por decisión de producto (docs/PRIVACY.md): lo propio
    // usa la foto real del usuario (Google o avatar elegido) y lo ajeno, la
    // del autor; si un autor no tiene avatar, cae el anónimo. El servidor
    // solo manda el primer nombre, nunca el completo.
    final user = ref.watch(currentUserProvider);
    final authorName = sighting.isMine
        ? (user?.displayName ?? 'Explorador')
        : (sighting.authorName ?? 'Un guardián del bosque');
    final authorImage = sighting.isMine
        ? avatarImageFor(user?.avatarUrl)
        : avatarImageFor(sighting.authorAvatar);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
      onTap: () => SightingDetailsModal.show(context, sighting, locationFull, ref.read(sightingsProvider).sightings.length),
      borderRadius: BorderRadius.circular(16),
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
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Autor: foto más grande con el primer nombre debajo.
                    // Lo propio usa tu foto real (Google o avatar elegido);
                    // lo ajeno, la del autor — el servidor manda
                    // `author_avatar` en el feed. `Expanded` hace que el
                    // nombre ceda espacio cuando el corazón a la derecha
                    // ocupa más (contadores de 3 cifras, etc.) — antes con
                    // ancho fijo de 82px desbordaba la tarjeta en pantallas
                    // estrechas.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipOval(
                            child: SizedBox(
                              width: 34,
                              height: 34,
                              child: authorImage != null
                                  ? Image(
                                      image: authorImage,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) =>
                                          const Icon(Icons.person, size: 18),
                                    )
                                  : Container(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      child: Icon(
                                        sighting.isMine
                                            ? Icons.person
                                            : Icons.eco_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            authorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Derecha: cantidad de luciérnagas encima del corazón.
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
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
                        const SizedBox(height: 3),
                        // No se ofrece dar corazón a algo `isPending`: todavía
                        // no existe en el servidor (`toggleLike` fallaría con
                        // un id nulo), así que aquí solo hay hueco vacío hasta
                        // que sincronice.
                        if (!sighting.isPending) LikeButton(sighting: sighting),
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
    );
  }
}

/// Corazón + contador, en la esquina donde antes había un '✨' decorativo.
/// Ver `LikeButton` (features/sightings/widgets) — compartido con el feed
/// de publicaciones. `GestureDetector` propio para que tocarlo no abra el
/// modal (el de la tarjeta entera) — solo da o quita el corazón.
///
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

