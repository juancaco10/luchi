import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/firefly_colors.dart';
import '../../../features/sightings/models/sighting_model.dart';
import '../../../features/sightings/providers/sightings_provider.dart';
import '../../../features/sightings/utils/sighting_format.dart';

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

class _SightingCard extends StatelessWidget {
  final SightingModel sighting;

  const _SightingCard({required this.sighting});

  @override
  Widget build(BuildContext context) {
    final location = sightingLocationLabel(sighting);

    return GestureDetector(
      onTap: () => _SightingDetailsDialog.show(context, sighting, location),
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
                                location,
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
                        relativeTime(sighting.createdAt),
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
                        const CircleAvatar(
                          radius: 9,
                          backgroundImage: AssetImage('assets/images/avatar_mateo.png'),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'x${sighting.quantity}',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const Text('✨', style: TextStyle(fontSize: 12)),
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

class _SightingDetailsDialog {
  static void show(BuildContext context, SightingModel sighting, String location) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: context.colors.surface,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🌎 $location',
                  style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  '✨ ${sighting.quantity} luciérnaga(s)',
                  style: context.text.bodyMedium,
                ),
                if (sighting.notes?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(sighting.notes!, style: context.text.bodyMedium),
                ],
                const SizedBox(height: 8),
                Text(
                  sighting.isPending ? 'Pendiente de enviar' : relativeTime(sighting.createdAt),
                  style: context.text.bodySmall?.copyWith(
                    color: context.text.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 20),
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
        );
      },
    );
  }
}
