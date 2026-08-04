import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/firefly_colors.dart';
import '../../sightings/models/sighting_model.dart';
import '../../sightings/providers/sightings_provider.dart';

class RecentSightings extends ConsumerWidget {
  const RecentSightings({super.key});

  /// Cuántas tarjetas caben sin que la fila se vuelva un scroll infinito.
  static const _maxCards = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sightingsProvider);
    final sightings = state.sightings.take(_maxCards).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Avistamientos Recientes',
              style: context.text.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/map'),
              child: const Text('Ver mapa'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (state.isLoading && sightings.isEmpty)
          const SizedBox(
            height: 152,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (sightings.isEmpty)
          const _EmptyState()
        else
          SizedBox(
            height: 152,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: sightings.length,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) =>
                  _SightingCard(sighting: sightings[index]),
            ),
          ),
      ],
    );
  }
}

/// Sin avistamientos todavía no se enseñan tarjetas de relleno: se invita a
/// registrar el primero, que es la acción que realmente queremos.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: context.firefly.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.firefly.cardBorder),
      ),
      child: Column(
        children: [
          Text('🔦', style: TextStyle(fontSize: 28, color: context.colors.primary)),
          const SizedBox(height: 8),
          Text(
            'Aún no has registrado avistamientos',
            textAlign: TextAlign.center,
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => context.go('/sightings/new'),
            icon: const Icon(Icons.add_a_photo_outlined, size: 18),
            label: const Text('Registrar el primero'),
          ),
        ],
      ),
    );
  }
}

class _SightingCard extends StatelessWidget {
  const _SightingCard({required this.sighting});

  final SightingModel sighting;

  /// "hace 2 h" a partir del ISO-8601 que devuelve el backend.
  String get _relativeTime {
    final creado = DateTime.tryParse(sighting.createdAt);
    if (creado == null) return '';
    final diff = DateTime.now().difference(creado);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} d';
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = sighting.photoUrl;

    return Semantics(
      label: '${sighting.locationName ?? 'Avistamiento'}, $_relativeTime',
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: context.firefly.cardSurface,
          border: Border.all(color: context.firefly.cardBorder),
          boxShadow: context.firefly.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 80,
                width: double.infinity,
                // Las fotos del usuario viven en el servidor; no hay ningún
                // asset local de relleno (el que había, forest_bg.jpg, no
                // existía y daba 404 en cada tarjeta).
                child: photoUrl == null || photoUrl.isEmpty
                    ? _Placeholder(pending: sighting.isPending)
                    : Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) =>
                            _Placeholder(pending: sighting.isPending),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      sighting.locationName?.isNotEmpty == true
                          ? sighting.locationName!
                          : 'Sin ubicación',
                      style: context.text.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.colors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          sighting.isPending
                              ? Icons.cloud_upload_outlined
                              : Icons.access_time_rounded,
                          size: 12,
                          color: context.text.bodySmall?.color,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            sighting.isPending ? 'Sin enviar' : _relativeTime,
                            style: context.text.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.pending});

  final bool pending;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.primary.withValues(alpha: 0.12),
      child: Center(
        child: Icon(
          pending ? Icons.cloud_off_outlined : Icons.emoji_nature,
          color: context.colors.primary,
          size: 28,
        ),
      ),
    );
  }
}
