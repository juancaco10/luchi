import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/firefly_colors.dart';
import '../models/sighting_model.dart';
import '../providers/sightings_provider.dart';
import '../utils/sighting_format.dart';
import '../utils/sighting_actions.dart';
import '../widgets/sighting_date_filter.dart';
import '../../../widgets/hardware_back_route.dart';
import '../../../widgets/ad_banner.dart';

/// Sede de editar / archivar / filtrar por fecha para los avistamientos
/// propios — no existía ninguna pantalla de lista antes de esto, solo el
/// mapa (que no permite estas acciones).
class MySightingsScreen extends ConsumerStatefulWidget {
  const MySightingsScreen({super.key});

  @override
  ConsumerState<MySightingsScreen> createState() => _MySightingsScreenState();
}

class _MySightingsScreenState extends ConsumerState<MySightingsScreen> {
  SightingDateFilter _filter = SightingDateFilter.all;
  bool _showingArchived = false;
  bool _archivedLoaded = false;

  void _toggleArchivedView() {
    if (!_archivedLoaded) {
      ref.read(sightingsProvider.notifier).loadArchivedSightings();
      _archivedLoaded = true;
    }
    setState(() => _showingArchived = !_showingArchived);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sightingsProvider);
    final source = _showingArchived ? state.archivedSightings : state.sightings;
    final visible =
        _showingArchived ? source : source.where((s) => _filter.matches(s)).toList();

    return HardwareBackRoute(
      onBack: () => context.go('/home'),
      child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/home'),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.firefly.cardSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.firefly.cardBorder),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          color: context.text.bodyMedium?.color, size: 18),
                    ),
                    style: IconButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _showingArchived ? 'Archivados' : 'Mis avistamientos',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: context.colors.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: _showingArchived ? 'Ver activos' : 'Ver archivados',
                    onPressed: _toggleArchivedView,
                    icon: Icon(
                      _showingArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                      color: context.text.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
            if (!_showingArchived)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: SightingDateFilterChips(
                  selected: _filter,
                  onChanged: (f) => setState(() => _filter = f),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: state.isLoading && source.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : (!_showingArchived && state.error != null && source.isEmpty)
                      ? _ErrorState(
                          message: state.error!,
                          onRetry: () => ref
                              .read(sightingsProvider.notifier)
                              .loadSightings(),
                        )
                      : visible.isEmpty
                      ? _EmptyState(showingArchived: _showingArchived)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: visible.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) => _SightingListTile(
                            sighting: visible[index],
                            isArchived: _showingArchived,
                            onEdit: () => context.go('/sightings/${visible[index].id}/edit'),
                            onArchive: (archived) =>
                                archiveSighting(context, ref, visible[index], archived),
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: _showingArchived
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.go('/sightings/new'),
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.onPrimary,
              icon: const Text('✨', style: TextStyle(fontSize: 18)),
              label: const Text(
                'Registrar',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
      bottomNavigationBar: const AdBanner(),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('☁️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                color: context.text.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool showingArchived;
  const _EmptyState({required this.showingArchived});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(showingArchived ? '🗃️' : '🗺️', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              showingArchived ? 'No hay avistamientos archivados' : 'Nada por aquí todavía',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.colors.onSurface,
              ),
            ),
            if (!showingArchived) ...[
              const SizedBox(height: 6),
              Text(
                'Prueba con otro filtro de fecha o registra uno nuevo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  color: context.text.bodyMedium?.color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SightingListTile extends StatelessWidget {
  final SightingModel sighting;
  final bool isArchived;
  final VoidCallback onEdit;
  final void Function(bool archived) onArchive;

  const _SightingListTile({
    required this.sighting,
    required this.isArchived,
    required this.onEdit,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.firefly.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.firefly.cardBorder),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 56,
              height: 56,
              child: sighting.photoUrl != null
                  ? Image.network(
                      sighting.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => _placeholderThumb(context),
                    )
                  : _placeholderThumb(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✨ x${sighting.quantity} · ${sightingLocationLabel(sighting)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  relativeTime(sighting.createdAt),
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: context.text.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          if (!isArchived)
            IconButton(
              tooltip: 'Editar',
              onPressed: onEdit,
              icon: Icon(Icons.edit_outlined, color: context.text.bodyMedium?.color, size: 20),
            ),
          IconButton(
            tooltip: isArchived ? 'Restaurar' : 'Archivar',
            onPressed: () => onArchive(!isArchived),
            icon: Icon(
              isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
              color: context.text.bodyMedium?.color,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderThumb(BuildContext context) {
    return Container(
      color: context.firefly.glow,
      child: const Center(child: Text('✨', style: TextStyle(fontSize: 22))),
    );
  }
}
