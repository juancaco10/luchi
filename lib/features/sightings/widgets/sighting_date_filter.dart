import 'package:flutter/material.dart';
import '../../../core/theme/firefly_colors.dart';
import '../models/sighting_model.dart';
import '../utils/sighting_format.dart';

enum SightingDateFilter { today, week, month, all }

extension SightingDateFilterX on SightingDateFilter {
  String get label => switch (this) {
        SightingDateFilter.today => 'Hoy',
        SightingDateFilter.week => 'Esta semana',
        SightingDateFilter.month => 'Este mes',
        SightingDateFilter.all => 'Todos',
      };

  /// `parseSightingDate` (no `DateTime.tryParse` crudo) porque el backend
  /// manda `created_at` en UTC explícito: comparar eso contra
  /// `DateTime.now()` local sin convertir hacía que un avistamiento de hoy
  /// por la noche cayera fuera de "Hoy" según el huso horario.
  bool matches(SightingModel s, {DateTime? now}) {
    if (this == SightingDateFilter.all) return true;
    final date = parseSightingDate(s.createdAt);
    if (date == null) return true;
    final n = now ?? DateTime.now();
    return switch (this) {
      SightingDateFilter.today =>
        date.year == n.year && date.month == n.month && date.day == n.day,
      SightingDateFilter.week => n.difference(date).inDays < 7,
      SightingDateFilter.month => date.year == n.year && date.month == n.month,
      SightingDateFilter.all => true,
    };
  }
}

/// Fila horizontal de chips Hoy/Esta semana/Este mes/Todos, con un control
/// opcional fijo a la derecha (p. ej. un filtro extra) que no se va con el
/// scroll de los chips.
class SightingDateFilterChips extends StatelessWidget {
  const SightingDateFilterChips({
    super.key,
    required this.selected,
    required this.onChanged,
    this.trailing,
  });

  final SightingDateFilter selected;
  final ValueChanged<SightingDateFilter> onChanged;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final filter in SightingDateFilter.values) ...[
                  _Chip(
                    filter: filter,
                    selected: selected == filter,
                    onTap: () => onChanged(filter),
                  ),
                  if (filter != SightingDateFilter.values.last)
                    const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.filter, required this.selected, required this.onTap});

  final SightingDateFilter filter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(filter.label),
      selected: selected,
      onSelected: (_) => onTap(),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      labelStyle: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: selected ? context.colors.onPrimary : context.text.bodyMedium?.color,
      ),
    );
  }
}
