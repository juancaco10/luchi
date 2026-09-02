import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/firefly_colors.dart';
import '../../../core/utils/constants.dart';
import '../models/sighting_model.dart';
import '../providers/sightings_provider.dart';
import '../utils/sighting_geocoding.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // El feed comunitario se carga solo cuando esta pantalla se abre (no en
    // el constructor del provider) y se refresca al volver a entrar, así
    // los avistamientos nuevos aparecen sin reiniciar la app.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCommunity();
    });
  }

  /// Carga el feed y, si el primer intento falló (conexión móvil lenta,
  /// primer TLS handshake de Hostinger que se cae), reintenta una vez a
  /// los 3s. Sin esto, un timeout puntual dejaba el mapa solo con los
  /// puntos propios sin ninguna recuperación salvo reiniciar la app.
  Future<void> _loadCommunity() async {
    final notifier = ref.read(sightingsProvider.notifier);
    await notifier.loadCommunitySightings();
    final stillEmpty = ref.read(sightingsProvider).communitySightings.isEmpty;
    if (!mounted || !stillEmpty) return;
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) notifier.loadCommunitySightings();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    final zoom = (camera.zoom + delta).clamp(3.0, 20.0);
    _mapController.move(camera.center, zoom);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sightingsProvider);

    // El mapa mezcla dos fuentes:
    //   1. El feed comunitario (GET /sightings): lo aprobado por
    //      moderación de otras familias + lo propio (aprobado o pendiente,
    //      ver sightings.php).
    //   2. La cola offline local: avistamientos creados sin conexión que
    //      aún no han subido; se marcan `is_pending` para que el niño vea
    //      que el suyo está en camino, no perdido.
    // Además entran como "pendiente" los propios que el servidor aún no ha
    // moderado (moderation_status del GET /my-sightings): sin ellos, un
    // avistamiento recién creado desaparecería del mapa al reiniciar la
    // app, hasta que la moderación lo apruebe.
    final ownPending = state.sightings
        .where((s) => s.isPending || s.moderationStatus == 'pending')
        .toList();
    final seen = <int?>{};
    final sightings = <SightingModel>[
      for (final s in [...ownPending, ...state.communitySightings])
        if (seen.add(s.id)) s,
    ]
        // Un avistamiento con coordenada centinela (país sin lista fija,
        // registrado sin conexión, todavía sin resolver) no tiene dónde
        // pintarse de verdad — sin filtrarlo, cae literalmente en el golfo
        // de Guinea y, si es el más reciente, el mapa abre centrado ahí.
        .where((s) => !isUnresolvedCoordinate(s.lat, s.lng))
        .toList();

    // Default center — Latin America
    const defaultCenter = LatLng(-34.6037, -58.3816); // Buenos Aires

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: sightings.isNotEmpty
                  ? LatLng(sightings.first.lat, sightings.first.lng)
                  : defaultCenter,
              initialZoom: sightings.isNotEmpty ? 12.0 : 4.0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              minZoom: 3.0,
              maxZoom: 20.0,
            ),
            children: [
              // Basemap de OpenStreetMap: gratis y sin API key. Antes usaba
              // CartoDB (basemaps.cartocdn.com), que pasó a exigir key y
              // rompía el mapa con "API key required". OSM no la pide.
              //
              // `ColorFiltered` con una matriz de inversión convierte el
              // mapa claro de OSM en uno oscuro (fondo casi negro, calles
              // claras) sin depender de un segundo proveedor de teselas
              // (que es justo lo que rompió antes): los puntos amarillos de
              // avistamientos (`context.colors.primary` en el tema oscuro,
              // ver `_SightingMarker`) se perdían contra el fondo claro
              // original y ahora resaltan con claridad.
              ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  -1, 0, 0, 0, 255,
                  0, -1, 0, 0, 255,
                  0, 0, -1, 0, 255,
                  0, 0, 0, 1, 0,
                ]),
                child: TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  maxZoom: 19,
                  userAgentPackageName: 'com.guardianes.luciernagas',
                ),
              ),

              // Sighting markers
              MarkerLayer(
                markers: sightings.map((s) {
                  return Marker(
                    point: LatLng(s.lat, s.lng),
                    width: 26,
                    height: 26,
                    child: _SightingMarker(
                      quantity: s.quantity,
                      isPending: s.isPending || s.moderationStatus == 'pending',
                    ),
                  );
                }).toList(),
              ),

              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    '© OpenStreetMap contributors',
                  ),
                ],
              ),
            ],
          ),

          // Top overlay
          SafeArea(
            child: Column(
              children: [
                // Header — pestaña de nivel superior (accesible desde el menú
                // inferior): sin flecha de retroceso, solo el título.
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Text(
                        'Avistamientos',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: context.colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // "Mis avistamientos" → lleva a la lista propia
                // (my_sightings_screen.dart), donde sí se pueden editar y
                // archivar. El mapa de esta pantalla es la vista general;
                // esta tarjeta es la puerta a los detalles.
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.colors.surface.withValues(alpha: 0.92),
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadius),
                    border: Border.all(color: context.firefly.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Mis avistamientos',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: context.colors.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.firefly.glow,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '✨ ${state.sightings.length}',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: context.colors.primary,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => context.go('/sightings'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Ver',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Error de carga visible: un fallo de red o del servidor no
                // debe parecer "avistamientos perdidos". Con reintento para
                // que el niño (o el adulto) pueda recargar sin reiniciar.
                if (state.error != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: context.firefly.warning.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppConstants.borderRadius),
                      border: Border.all(
                        color: context.firefly.warning.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            state.error!,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: context.colors.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            final notifier =
                                ref.read(sightingsProvider.notifier);
                            notifier.loadSightings();
                            notifier.loadCommunitySightings();
                          },
                          child: const Text(
                            'Reintentar',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Escala de zoom al costado: para acercar/alejar y así
          // "agrandar o achicar" los puntos sin pellizcar (más fácil para
          // niños). Los marcadores siempre tienen el mismo tamaño en
          // pantalla; el zoom es lo que separa o agrupa los puntos.
          Positioned(
            right: 12,
            bottom: 116,
            child: Column(
              children: [
                _ZoomButton(
                  icon: Icons.add_rounded,
                  onTap: () => _zoomBy(1),
                ),
                const SizedBox(height: 8),
                _ZoomButton(
                  icon: Icons.remove_rounded,
                  onTap: () => _zoomBy(-1),
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
          if (sightings.isEmpty && !state.isLoading && !state.isLoadingCommunity)
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
                .withValues(alpha: 0.45),
            blurRadius: 7,
            spreadRadius: 0.8,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('✨', style: TextStyle(fontSize: 9)),
            if (quantity > 1)
              Text(
                'x$quantity',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 6,
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

/// Botón circular de zoom (arriba/abajo) al costado del mapa.
class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.isDark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 24, color: context.colors.onSurface),
        ),
      ),
    );
  }
}
