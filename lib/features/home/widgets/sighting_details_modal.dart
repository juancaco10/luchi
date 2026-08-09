import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/firefly_colors.dart';
import '../../../features/sightings/models/sighting_model.dart';
import '../../../features/sightings/providers/sightings_provider.dart';
import '../../../features/sightings/utils/sighting_format.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/profile/utils/avatar_image.dart';

class SightingDetailsModal extends ConsumerStatefulWidget {
  final SightingModel sighting;
  final String location;
  final int totalSightings; // For the profile button logic

  const SightingDetailsModal({
    super.key,
    required this.sighting,
    required this.location,
    required this.totalSightings,
  });

  static void show(BuildContext context, SightingModel sighting, String location, int totalSightings) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SightingDetailsModal(
          sighting: sighting,
          location: location,
          totalSightings: totalSightings,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            child: child,
          ),
        );
      },
    );
  }

  @override
  ConsumerState<SightingDetailsModal> createState() => _SightingDetailsModalState();
}

class _SightingDetailsModalState extends ConsumerState<SightingDetailsModal> {
  @override
  Widget build(BuildContext context) {
    // Si es un avistamiento ajeno del feed comunitario (`isMine == false`),
    // `sightingByIdProvider` mantiene actualizado el contador de corazones
    // en vivo aunque el modal ya esté abierto; si es tuyo o no tiene id
    // (offline, aún sin sincronizar) se usa el widget tal cual llegó.
    final live = widget.sighting.id != null
        ? ref.watch(sightingByIdProvider(widget.sighting.id!))
        : null;
    final sighting = live ?? widget.sighting;

    final user = ref.watch(currentUserProvider);
    // Nunca el nombre real de otra persona: `isMine` lo decide el
    // servidor (ver GET /sightings en backend/api/routes/sightings.php),
    // así que un avistamiento ajeno siempre se muestra anónimo aquí, sin
    // depender de que el cliente "recuerde" ocultarlo.
    final userName = sighting.isMine
        ? (user?.name.split(' ').first ?? 'Explorador')
        : 'Un guardián del bosque';

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Imagen grande (o placeholder)
                Flexible(
                  child: Stack(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 300,
                        child: sighting.photoUrl != null
                            ? Image.network(
                                sighting.photoUrl!,
                                fit: BoxFit.cover,
                              )
                            : DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: context.firefly.primaryGradient,
                                ),
                                child: const Center(
                                  child: Text('✨', style: TextStyle(fontSize: 64)),
                                ),
                              ),
                      ),
                      // Degradado para la parte superior (botones)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 80,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.6),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Botón cerrar
                      Positioned(
                        top: 16,
                        right: 16,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 28),
                          onPressed: () => Navigator.of(context).pop(),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Detalles
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Usuario y Fecha
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                // Foto real del autor, más grande: lo propio
                                // usa la del usuario actual (Google o avatar
                                // elegido); lo ajeno, anónimo siempre.
                                sighting.isMine
                                    ? ClipOval(
                                        child: SizedBox(
                                          width: 52,
                                          height: 52,
                                          child: Builder(builder: (context) {
                                            final image =
                                                avatarImageFor(user?.avatarUrl);
                                            return image != null
                                                ? Image(
                                                    image: image,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (c, e, s) =>
                                                        const Icon(
                                                            Icons.person,
                                                            size: 26),
                                                  )
                                                : Container(
                                                    decoration: BoxDecoration(
                                                      gradient: context
                                                          .firefly
                                                          .primaryGradient,
                                                    ),
                                                    child: const Center(
                                                      child: Text('👦',
                                                          style: TextStyle(
                                                              fontSize: 26)),
                                                    ),
                                                  );
                                          }),
                                        ),
                                      )
                                    : CircleAvatar(
                                        radius: 26,
                                        backgroundColor:
                                            context.firefly.cardSurface,
                                        child: Icon(Icons.eco_rounded,
                                            color: context.colors.primary,
                                            size: 26),
                                      ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        userName,
                                        style: context.text.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (sighting.isPending)
                                        Text(
                                          'Pendiente de enviar',
                                          style: context.text.bodySmall?.copyWith(
                                            color: context.text.bodySmall?.color
                                                ?.withValues(alpha: 0.7),
                                          ),
                                        )
                                      else ...[
                                        // Fecha y hora reales de la publicación, y
                                        // debajo el "hace cuánto" en tono apagado —
                                        // lo pedido: no solo relativo, la fecha
                                        // absoluta también visible.
                                        Text(
                                          absoluteDateTime(sighting.createdAt),
                                          style: context.text.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          relativeTimeLong(sighting.createdAt),
                                          style: context.text.bodySmall?.copyWith(
                                            color: context.text.bodySmall?.color
                                                ?.withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Me gusta — corazón real conectado a sightingsProvider,
                          // ya no un bool local que se olvidaba al cerrar el modal.
                          // Grande y con el contador SIEMPRE al lado (incluso en 0).
                          if (!sighting.isPending && sighting.id != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    sighting.likedByMe
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: sighting.likedByMe
                                        ? const Color(0xFFFF5C7A)
                                        : context.text.bodyMedium?.color,
                                    size: 34,
                                  ),
                                  onPressed: () => ref
                                      .read(sightingsProvider.notifier)
                                      .toggleLike(sighting.id!),
                                ),
                                Text(
                                  '${sighting.likesCount}',
                                  style: context.text.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Ubicación
                      Row(
                        children: [
                          Icon(Icons.location_on, color: context.colors.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.location,
                              style: context.text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Cantidad y notas
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: context.isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Text('✨', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${sighting.quantity} luciérnaga(s)',
                                    style: context.text.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (sighting.notes?.trim().isNotEmpty == true) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      sighting.notes!,
                                      style: context.text.bodyMedium,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Botón ver perfil — solo tiene sentido sobre tu propio
                      // avistamiento; sobre uno ajeno del feed comunitario no
                      // hay perfil que mostrar (sería revelar quién es).
                      if (sighting.isMine && widget.totalSightings > 1) ...[
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonalIcon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              // En un futuro llevaría al perfil del usuario.
                              // Por ahora cerramos el modal o vamos a un placeholder.
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Próximamente: Perfil de usuario')),
                              );
                            },
                            icon: const Icon(Icons.person),
                            label: const Text('Ver perfil completo'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
