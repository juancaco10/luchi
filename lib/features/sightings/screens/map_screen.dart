import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../providers/sightings_provider.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sightingsProvider);
    final sightings = state.sightings;

    // Default center — Latin America
    const defaultCenter = LatLng(-34.6037, -58.3816); // Buenos Aires

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: sightings.isNotEmpty
                  ? LatLng(sightings.first.lat, sightings.first.lng)
                  : defaultCenter,
              initialZoom: sightings.isNotEmpty ? 12.0 : 4.0,
              backgroundColor: AppColors.background,
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
                    color: AppColors.surface.withOpacity(0.92),
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadius),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go('/home'),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppColors.textSecondary, size: 18),
                        style: IconButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(32, 32)),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mis avistamientos',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Tus registros en el mundo real',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGlow,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '✨ ${sightings.length}',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
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
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
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
                  color: AppColors.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🗺️', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    const Text(
                      'Aún no hay avistamientos',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '¡Sé el primero en registrar una luciérnaga en tu zona!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        color: AppColors.textSecondary,
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
            ? AppColors.warning.withOpacity(0.9)
            : AppColors.primary.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isPending ? AppColors.warning : AppColors.primary)
                .withOpacity(0.5),
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
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textOnPrimary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
