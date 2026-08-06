import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/firefly_colors.dart';
import '../models/sighting_model.dart';
import '../providers/sightings_provider.dart';
import '../utils/sighting_format.dart';

enum _DateFilter { today, week, month, all }

/// Sede de editar / archivar / filtrar por fecha para los avistamientos
/// propios — no existía ninguna pantalla de lista antes de esto, solo el
/// mapa (que no permite estas acciones).
class MySightingsScreen extends ConsumerStatefulWidget {
  const MySightingsScreen({super.key});

  @override
  ConsumerState<MySightingsScreen> createState() => _MySightingsScreenState();
}

class _MySightingsScreenState extends ConsumerState<MySightingsScreen> {
  _DateFilter _filter = _DateFilter.all;
  bool _showingArchived = false;
  bool _archivedLoaded = false;

  bool _matchesFilter(SightingModel s) {
    final date = DateTime.tryParse(s.createdAt);
    if (date == null) return true;
    final now = DateTime.now();
    switch (_filter) {
      case _DateFilter.today:
        return date.year == now.year && date.month == now.month && date.day == now.day;
      case _DateFilter.week:
        return now.difference(date).inDays < 7;
      case _DateFilter.month:
        return date.year == now.year && date.month == now.month;
      case _DateFilter.all:
        return true;
    }
  }

  void _toggleArchivedView() {
    if (!_archivedLoaded) {
      ref.read(sightingsProvider.notifier).loadArchivedSightings();
      _archivedLoaded = true;
    }
    setState(() => _showingArchived = !_showingArchived);
  }

  Future<void> _archive(SightingModel s, bool archived) async {
    final notifier = ref.read(sightingsProvider.notifier);
    final ok = await notifier.setArchived(s.id!, archived);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            archived ? 'Avistamiento archivado' : 'Avistamiento restaurado',
            style: const TextStyle(fontFamily: 'Nunito'),
          ),
          backgroundColor: context.firefly.cardSurface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: archived
              ? SnackBarAction(
                  label: 'Deshacer',
                  onPressed: () => ref.read(sightingsProvider.notifier).setArchived(s.id!, false),
                )
              : null,
        ),
      );
    } else {
      final error = ref.read(sightingsProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'No se pudo completar la acción',
              style: const TextStyle(fontFamily: 'Nunito')),
          backgroundColor: context.colors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sightingsProvider);
    final source = _showingArchived ? state.archivedSightings : state.sightings;
    final visible = _showingArchived ? source : source.where(_matchesFilter).toList();

    return Scaffold(
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
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Hoy',
                        selected: _filter == _DateFilter.today,
                        onTap: () => setState(() => _filter = _DateFilter.today),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Esta semana',
                        selected: _filter == _DateFilter.week,
                        onTap: () => setState(() => _filter = _DateFilter.week),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Este mes',
                        selected: _filter == _DateFilter.month,
                        onTap: () => setState(() => _filter = _DateFilter.month),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Todos',
                        selected: _filter == _DateFilter.all,
                        onTap: () => setState(() => _filter = _DateFilter.all),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: state.isLoading && source.isEmpty
                  ? const Center(child: CircularProgressIndicator())
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
                            onArchive: (archived) => _archive(visible[index], archived),
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
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: selected ? context.colors.onPrimary : context.text.bodyMedium?.color,
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
