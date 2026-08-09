import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/firefly_colors.dart';
import '../../education/providers/chapters_provider.dart';

/// "Tu Progreso Educativo" — antes era `ProgressCard(completedChapters: 2,
/// totalChapters: 5)` con datos inventados y fijos en el `HomeScreen`
/// (solo existen 4 capítulos reales), no tocable, y sin decir qué
/// desbloqueaba. Ahora lee `chaptersProvider` de verdad y lleva a
/// `/chapters`, la lista que ya muestra bloqueo/completado por capítulo.
class ProgressCard extends ConsumerWidget {
  const ProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapters = ref.watch(chaptersProvider).chapters;
    final total = chapters.length;
    final completed = chapters.where((c) => c.isCompleted).length;
    final progress = total == 0 ? 0.0 : completed / total;
    final finished = total > 0 && completed == total;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.go('/chapters'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: context.firefly.cardSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.firefly.cardBorder, width: 2),
            boxShadow: context.firefly.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tu Progreso Educativo',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: context.colors.onSurface,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.firefly.glow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(progress * 100).toInt()}%',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: context.colors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded,
                          size: 20, color: context.colors.onSurface.withValues(alpha: 0.4)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: context.colors.surface,
                  valueColor: AlwaysStoppedAnimation(context.firefly.success),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                total == 0
                    ? 'Cargando capítulos…'
                    : finished
                        ? '¡Completaste los $total capítulos! Sigue jugando para ganar más puntos.'
                        : '$completed de $total capítulos completados · '
                            'completa uno para desbloquear el siguiente',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  color: context.colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
