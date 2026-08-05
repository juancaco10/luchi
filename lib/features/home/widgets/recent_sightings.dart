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
        const SizedBox(height: 8),
        if (state.isLoading && sightings.isEmpty)
          const SizedBox(
            height: 130,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (sightings.isEmpty)
          const _EmptyState()
        else
          SizedBox(
            height: 130,
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

    // Try to extract country or simplified location (last part after comma)
    String displayLocation = 'Sin ubicación';
    final loc = sighting.locationName;
    if (loc != null && loc.isNotEmpty) {
      if (loc.contains(',')) {
        displayLocation = loc.split(',').last.trim();
      } else {
        displayLocation = loc;
      }
    }
    // If it looks like coordinates, replace it
    if (displayLocation.contains(RegExp(r'[0-9]+\.[0-9]+'))) {
      displayLocation = 'Ubicación remota';
    }

    return Semantics(
      label: '$displayLocation, $_relativeTime',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _showSightingDetails(context, sighting, displayLocation, _relativeTime);
        },
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
                height: 54,
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
                      displayLocation,
                      style: context.text.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.colors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
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
    ));
  }

  void _showSightingDetails(BuildContext context, SightingModel sighting, String displayLocation, String relativeTime) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          backgroundColor: context.firefly.cardSurface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (sighting.photoUrl != null && sighting.photoUrl!.isNotEmpty)
                SizedBox(
                  height: 200,
                  child: Image.network(
                    sighting.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      color: context.colors.primary.withValues(alpha: 0.12),
                      child: Icon(Icons.broken_image_rounded, size: 40, color: context.colors.primary),
                    ),
                  ),
                )
              else
                Container(
                  height: 120,
                  color: context.colors.primary.withValues(alpha: 0.12),
                  child: Icon(Icons.emoji_nature, size: 48, color: context.colors.primary),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🌎 $displayLocation',
                      style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 16, color: context.colors.onSurface.withValues(alpha: 0.7)),
                        const SizedBox(width: 6),
                        Text(relativeTime, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurface.withValues(alpha: 0.7))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: context.colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bug_report_rounded, size: 18, color: context.colors.primary),
                          const SizedBox(width: 8),
                          Text(
                            '${sighting.quantity} luciérnaga${sighting.quantity != 1 ? 's' : ''}',
                            style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: context.colors.primary),
                          ),
                        ],
                      ),
                    ),
                    if (sighting.notes != null && sighting.notes!.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Detalles:',
                        style: context.text.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sighting.notes!,
                        style: context.text.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.tonal(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cerrar'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
