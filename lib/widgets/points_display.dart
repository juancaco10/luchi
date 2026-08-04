import 'package:flutter/material.dart';
import '../core/theme/firefly_colors.dart';

/// Compact points display badge
class PointsDisplay extends StatelessWidget {
  final int points;
  final bool compact;

  const PointsDisplay({super.key, required this.points, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 5 : 8,
      ),
      decoration: BoxDecoration(
        gradient: context.firefly.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.colors.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚡', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '$points pts',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.w800,
              color: context.colors.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
