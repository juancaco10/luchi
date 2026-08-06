import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/firefly_colors.dart';
import '../../../core/utils/constants.dart';
import '../providers/sightings_provider.dart';
import '../utils/sighting_geocoding.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sightingsProvider);
    // Un avistamiento con coordenada centinela (país sin lista fija,
    // registrado sin conexión, todavía sin resolver) no tiene dónde
    // pintarse de verdad — sin filtrarlo, cae literalmente en el golfo de
    // Guinea y, si es el más reciente, el mapa abre centrado ahí.
    final sightings =
        state.sightings.where((s) => !isUnresolvedCoordinate(s.lat, s.lng)).toList();

    // Default center — Latin America
    const defaultCenter = LatLng(-34.6037, -58.3816); // Buenos Aires

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: sightings.isNotEmpty
                  ? LatLng(sightings.first.lat, sightings.first.lng)
                  : defaultCenter,
              initialZoom: sightings.isNotEmpty ? 12.0 : 4.0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
            children: [
              // Dark tile layer
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                maxZoom: 20,
              ),

              // Sighting markers
              MarkerLayer(
                markers: sightings.map((s) {
                  return Marker(
                    point: LatLng(s.lat, s.lng),
                    width: 50,
                    height: 50,
                    child: _SightingMarker(
                      quantity: s.quantity,
                      isPending: s.isPending,
                    ),
                  );
                }).toList(),
              ),

              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors, © CARTO',
                  ),
                ],
              ),
            ],
          ),

          // Top overlay
          SafeArea(
            child: Column(
              children: [
                // Header bar
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.colors.surface.withValues(alpha: 0.92),
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadius),
                    border: Border.all(color: context.firefly.cardBorder),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go('/home'),
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                            color: context.text.bodyMedium?.color, size: 18),
                        style: IconButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(32, 32)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mis avistamientos',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: context.colors.onSurface,
                              ),
                            ),
                            Text(
                              'Tus registros en el mundo real',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                color: context.text.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Editar y archivar avistamientos',
                        onPressed: () => context.go('/sightings'),
                        icon: Icon(Icons.list_alt_rounded,
                            color: context.text.bodyMedium?.color, size: 20),
                        style: IconButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(32, 32)),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: context.firefly.glow,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '✨ ${sightings.length}',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: context.colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // FAB to add sighting
          Positioned(
            bottom: 32,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: () => context.go('/sightings/new'),
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.onPrimary,
              icon: const Text('✨', style: TextStyle(fontSize: 18)),
              label: const Text(
                'Registrar',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          // Empty state
          if (sightings.isEmpty && !state.isLoading)
            Center(
              child: Container(
                margin: const EdgeInsets.all(40),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.colors.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                  border: Border.all(color: context.firefly.cardBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🗺️', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text(
                      'Aún no hay avistamientos',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '¡Sé el primero en registrar una luciérnaga en tu zona!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        color: context.text.bodyMedium?.color,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => context.go('/sightings/new'),
                      child: const Text('Registrar mi primer avistamiento'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Map Marker ────────────────────────────────────────────────────

class _SightingMarker extends StatelessWidget {
  final int quantity;
  final bool isPending;

  const _SightingMarker({required this.quantity, required this.isPending});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isPending
            ? context.firefly.warning.withValues(alpha: 0.9)
            : context.colors.primary.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isPending ? context.firefly.warning : context.colors.primary)
                .withValues(alpha: 0.5),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('✨', style: TextStyle(fontSize: 16)),
            if (quantity > 1)
              Text(
                'x$quantity',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: context.colors.onPrimary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
