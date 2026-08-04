import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_provider.dart';

class ProgressCard extends ConsumerWidget {
  final int completedChapters;
  final int totalChapters;

  const ProgressCard({
    super.key,
    required this.completedChapters,
    required this.totalChapters,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final progress = totalChapters == 0 ? 0.0 : completedChapters / totalChapters;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2640) : const Color(0xFFE8EEF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          width: 2,
        ),
        boxShadow: [
          if (!isDark)
            const BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
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
                  color: isDark ? Colors.white : const Color(0xFF2C3E50),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5D020).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFD4A000), // Darker yellow for better contrast
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: isDark ? const Color(0xFF0B0F1A) : Colors.white,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF72E26E)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$completedChapters de $totalChapters capítulos completados',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              color: isDark ? Colors.white70 : const Color(0xFF5A6B8A),
            ),
          ),
        ],
      ),
    );
  }
}
