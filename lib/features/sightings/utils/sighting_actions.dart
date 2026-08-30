import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/firefly_colors.dart';
import '../models/sighting_model.dart';
import '../providers/sightings_provider.dart';

/// Archiva o desarchiva un avistamiento propio y muestra el resultado en un
/// SnackBar (con "Deshacer" al archivar) — compartido entre Mis
/// avistamientos y la tarjeta del feed de Publicaciones para no duplicar el
/// mismo flujo dos veces.
Future<void> archiveSighting(
  BuildContext context,
  WidgetRef ref,
  SightingModel sighting,
  bool archived,
) async {
  final notifier = ref.read(sightingsProvider.notifier);
  final ok = await notifier.setArchived(sighting.id!, archived);
  if (!context.mounted) return;
  // Sin esto, archivar varios avistamientos seguidos apila un SnackBar
  // detrás de otro (cada uno espera a que termine el anterior) — se
  // percibe como "el cartel no se va nunca" aunque cada uno individual sí
  // tenga una duración normal.
  ScaffoldMessenger.of(context).clearSnackBars();
  if (ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          archived ? 'Avistamiento archivado' : 'Avistamiento restaurado',
          // `cardSurface` cambia de oscuro a claro según el tema; sin un
          // color de texto explícito que la acompañe, el SnackBar caía en
          // el color por defecto de Material, que no siempre contrasta
          // con ese fondo — en modo oscuro quedaba prácticamente ilegible.
          style: TextStyle(fontFamily: 'Nunito', color: context.colors.onSurface),
        ),
        backgroundColor: context.firefly.cardSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: archived
            ? SnackBarAction(
                label: 'Deshacer',
                textColor: context.colors.primary,
                onPressed: () =>
                    ref.read(sightingsProvider.notifier).setArchived(sighting.id!, false),
              )
            : null,
      ),
    );
  } else {
    final error = ref.read(sightingsProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'No se pudo completar la acción',
            style: const TextStyle(fontFamily: 'Nunito', color: Colors.white)),
        backgroundColor: context.colors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
