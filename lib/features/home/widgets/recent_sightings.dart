import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_provider.dart';

class RecentSightings extends ConsumerWidget {
  const RecentSightings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Avistamientos Recientes',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF2C3E50),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Ver mapa'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return _SightingCard(
                image: 'assets/images/forest_bg.jpg', // Placeholder
                location: 'Parque Nacional',
                time: '${index + 1}h atrás',
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SightingCard extends ConsumerWidget {
  final String image;
  final String location;
  final String time;

  const _SightingCard({
    required this.image,
    required this.location,
    required this.time,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Container(
      width: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF1E2D4A) : Colors.white,
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE8EEF5),
          width: 1,
        ),
        boxShadow: [
          if (!isDark)
            const BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.asset(
              image,
              height: 80,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                height: 80,
                color: isDark ? const Color(0xFF2B3A5A) : const Color(0xFFF4F7FB),
                child: Icon(Icons.image_not_supported, color: isDark ? Colors.white54 : Colors.black26),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF2C3E50),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 10, color: isDark ? Colors.white54 : const Color(0xFF8F9FB9)),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 10,
                        color: isDark ? Colors.white54 : const Color(0xFF8F9FB9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
