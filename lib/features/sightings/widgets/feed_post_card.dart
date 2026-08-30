import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/firefly_colors.dart';
import '../../../core/utils/constants.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/home/widgets/sighting_details_modal.dart';
import '../../../features/profile/utils/avatar_image.dart';
import '../models/sighting_model.dart';
import '../providers/sightings_provider.dart';
import '../utils/sighting_actions.dart';
import '../utils/sighting_format.dart';
import 'coming_soon_control.dart';
import 'like_button.dart';

/// Tarjeta de una publicación del feed comunitario.
class FeedPostCard extends ConsumerWidget {
  const FeedPostCard({super.key, required this.post});

  final SightingModel post;

  void _openDetails(BuildContext context, WidgetRef ref) {
    SightingDetailsModal.show(
      context,
      post,
      sightingLocationLabel(post),
      ref.read(sightingsProvider).sightings.length,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final location = sightingShortLocationLabel(post);

    // Autor visible por decisión de producto (docs/PRIVACY.md): lo propio
    // usa el apodo/displayName del usuario actual; lo ajeno, el apodo (o
    // primer nombre) que manda el servidor.
    final authorName = post.isMine
        ? (user?.displayName ?? 'Explorador')
        : (post.authorName ?? 'Un guardián del bosque');
    final authorImage = post.isMine
        ? avatarImageFor(user?.avatarUrl)
        : avatarImageFor(post.authorAvatar);

    // No hay especie en el modelo (ver plan): el título usa la nota del
    // usuario si la hay, y si no un texto genérico no vacío — el diseño
    // depende de que estas dos líneas siempre tengan contenido. El
    // subtítulo es la ubicación completa, o el tiempo relativo cuando el
    // título ya cayó en el genérico (para que nunca sean la misma frase).
    final hasNotes = post.notes != null && post.notes!.trim().isNotEmpty;
    final title = hasNotes ? post.notes!.trim() : '✨ ${post.quantity} luciérnaga(s)';
    final subtitle = hasNotes ? sightingLocationLabel(post) : relativeTimeLong(post.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: context.firefly.cardSurface,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: context.firefly.cardBorder),
        boxShadow: context.firefly.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + nombre + ubicación + tiempo + menú
          InkWell(
            onTap: () => _openDetails(context, ref),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: AppConstants.feedAvatarSize,
                      height: AppConstants.feedAvatarSize,
                      child: authorImage != null
                          ? Image(
                              image: authorImage,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) =>
                                  const Icon(Icons.person, size: 20),
                            )
                          : Container(
                              color: context.colors.primary.withValues(alpha: 0.15),
                              child: Icon(
                                post.isMine ? Icons.person : Icons.eco_rounded,
                                size: 20,
                                color: context.colors.primary,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: context.colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 12, color: context.text.bodySmall?.color),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 11,
                                  color: context.text.bodySmall?.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    relativeTimeShort(post.createdAt),
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.text.bodySmall?.color,
                    ),
                  ),
                  _PostMenuButton(post: post, onViewDetails: () => _openDetails(context, ref)),
                ],
              ),
            ),
          ),

          // Foto con la insignia de cantidad encima
          InkWell(
            onTap: () => _openDetails(context, ref),
            child: Stack(
              children: [
                SizedBox(
                  height: AppConstants.feedPhotoHeight,
                  width: double.infinity,
                  child: post.photoUrl != null
                      ? Image.network(
                          post.photoUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) => progress == null
                              ? child
                              : _photoPlaceholder(context, loading: true),
                          errorBuilder: (context, error, stack) => _photoPlaceholder(context),
                        )
                      : _photoPlaceholder(context),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.firefly.cardSurface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(AppConstants.iconRadius),
                    ),
                    child: Text(
                      'x${post.quantity} ✨',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: context.colors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Título + subtítulo (sustitutos de especie — ver comentario arriba)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: context.firefly.success,
                  ),
                ),
              ],
            ),
          ),

          // Footer: corazón + comentario/marcador (desactivados) o pendiente
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 2),
            child: Row(
              children: [
                if (post.isPending)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Text(
                      '⏳ Pendiente de enviar',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.firefly.warning,
                      ),
                    ),
                  )
                else
                  LikeButton(sighting: post, overlay: false),
                ComingSoonControl(
                  message: 'Los comentarios llegan pronto 💬',
                  semanticsLabel: 'Comentarios',
                  child: Icon(Icons.chat_bubble_outline_rounded,
                      size: 20, color: context.text.bodyMedium?.color),
                ),
                const Spacer(),
                ComingSoonControl(
                  message: 'Guardar publicaciones llega pronto 🔖',
                  semanticsLabel: 'Guardar',
                  child: Icon(Icons.bookmark_border_rounded,
                      size: 20, color: context.text.bodyMedium?.color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostMenuButton extends StatelessWidget {
  const _PostMenuButton({required this.post, required this.onViewDetails});

  final SightingModel post;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final canManage = post.isMine && post.id != null;
    return Consumer(
      builder: (context, ref, _) => ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: AppConstants.minTouchTarget,
          minHeight: AppConstants.minTouchTarget,
        ),
        child: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, size: 20, color: context.text.bodyMedium?.color),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                context.go('/sightings/${post.id}/edit');
              case 'archive':
                archiveSighting(context, ref, post, true);
              case 'details':
                onViewDetails();
            }
          },
          itemBuilder: (context) => canManage
              ? const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'archive', child: Text('Archivar')),
                ]
              : const [
                  PopupMenuItem(value: 'details', child: Text('Ver detalles')),
                ],
        ),
      ),
    );
  }
}

Widget _photoPlaceholder(BuildContext context, {bool loading = false}) {
  return DecoratedBox(
    decoration: BoxDecoration(gradient: context.firefly.primaryGradient),
    child: Center(
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Text('✨', style: TextStyle(fontSize: 44)),
    ),
  );
}
