import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/firefly_colors.dart';
import '../../../core/utils/constants.dart';
import '../providers/sightings_provider.dart';
import '../widgets/coming_soon_control.dart';
import '../widgets/feed_post_card.dart';
import '../widgets/sighting_date_filter.dart';

/// Feed de publicaciones tipo red social: los avistamientos de todos los
/// usuarios (lo propio incluido), ordenados por fecha, con foto, autor,
/// ubicación, cantidad, nota y corazones. Es la pestaña "Publicaciones"
/// del menú inferior (sustituye a la antigua pestaña de Opciones, que
/// ahora vive dentro del Perfil).
class CommunityFeedScreen extends ConsumerStatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  ConsumerState<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends ConsumerState<CommunityFeedScreen> {
  SightingDateFilter _filter = SightingDateFilter.all;

  @override
  void initState() {
    super.initState();
    // Refresco no silencioso al entrar a esta pestaña: aquí sí se espera
    // que el usuario vea el spinner si hace falta red (es la pantalla
    // dedicada al feed, a diferencia del resumen del home).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(sightingsProvider.notifier).loadCommunitySightings();
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(sightingsProvider.notifier).loadSightings(),
      ref.read(sightingsProvider.notifier).loadCommunitySightings(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sightingsProvider);
    final allPosts = ref.watch(sightingsProvider.notifier).mergedFeed;
    final posts = _filter == SightingDateFilter.all
        ? allPosts
        : allPosts.where((p) => _filter.matches(p)).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header — pestaña de nivel superior: sin flecha, solo título.
            // Campana y lupa: sin backend de notificaciones/búsqueda
            // todavía, se dibujan atenuadas (ver ComingSoonControl).
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Publicaciones',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: context.colors.onSurface,
                      ),
                    ),
                  ),
                  ComingSoonControl(
                    message: 'Aquí verás tus avisos. ¡Muy pronto! 🔔',
                    semanticsLabel: 'Notificaciones',
                    child: Icon(Icons.notifications_none_rounded,
                        color: context.text.bodyMedium?.color),
                  ),
                  ComingSoonControl(
                    message: 'La búsqueda llega pronto 🔍',
                    semanticsLabel: 'Buscar',
                    child: Icon(Icons.search_rounded, color: context.text.bodyMedium?.color),
                  ),
                ],
              ),
            ),

            if (state.error != null && state.communitySightings.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.firefly.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
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
                        onPressed: () =>
                            ref.read(sightingsProvider.notifier).loadCommunitySightings(),
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
              ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SightingDateFilterChips(
                selected: _filter,
                onChanged: (f) => setState(() => _filter = f),
                trailing: ComingSoonControl(
                  message: 'Más filtros muy pronto ✨',
                  semanticsLabel: 'Más filtros',
                  child: Icon(Icons.tune_rounded, size: 20, color: context.text.bodyMedium?.color),
                ),
              ),
            ),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ComingSoonControl(
                message: 'Pronto podrás explorar por país 🌍',
                semanticsLabel: 'Filtrar por país',
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.firefly.cardSurface,
                    borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
                    border: Border.all(color: context.firefly.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.public_rounded, size: 16, color: context.text.bodyMedium?.color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Todos los países',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: context.colors.onSurface,
                          ),
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down_rounded,
                          size: 18, color: context.text.bodyMedium?.color),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
            Expanded(
              child: posts.isEmpty
                  ? _FeedEmptyState(
                      isLoading: state.isLoadingCommunity,
                      filtered: _filter != SightingDateFilter.all && allPosts.isNotEmpty,
                    )
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                        itemCount: posts.length,
                        itemBuilder: (context, index) => FeedPostCard(post: posts[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/sightings/new'),
        backgroundColor: context.colors.primary,
        foregroundColor: context.colors.onPrimary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }
}

class _FeedEmptyState extends StatelessWidget {
  final bool isLoading;
  final bool filtered;
  const _FeedEmptyState({required this.isLoading, this.filtered = false});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 3));
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(filtered ? '🔎' : '🪲', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              filtered ? 'Nada en este período' : 'Aún no hay publicaciones',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              filtered
                  ? 'No hay publicaciones en este período. Prueba con «Todos».'
                  : 'Cuando tú u otros guardianes registren luciérnagas, '
                      'aparecerán aquí. ¡Sé el primero!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: context.text.bodyMedium?.color,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
