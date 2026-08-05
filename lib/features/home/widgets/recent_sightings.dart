import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/firefly_colors.dart';

class RecentSightings extends ConsumerWidget {
  const RecentSightings({super.key});

  static final List<Map<String, dynamic>> _mockSightings = [
    {
      'image': 'assets/images/a1.jpg',
      'location': 'Rivera',
      'time': '2h',
      'user': 'María G.',
      'likes': 24,
      'avatar': 'assets/images/avatar_mateo.png',
    },
    {
      'image': 'assets/images/a2.jpg',
      'location': 'Artigas',
      'time': '5h',
      'user': 'Andrés M.',
      'likes': 18,
      'avatar': 'assets/images/avatar_mateo.png',
    },
    {
      'image': 'assets/images/a3.jpg',
      'location': 'Tacuarembó',
      'time': '1d',
      'user': 'Sofía R.',
      'likes': 31,
      'avatar': 'assets/images/avatar_mateo.png',
    },
    {
      'image': 'assets/images/a4.jpg',
      'location': 'Rivera',
      'time': '2d',
      'user': 'Carlos J.',
      'likes': 12,
      'avatar': 'assets/images/avatar_mateo.png',
    },
    {
      'image': 'assets/images/a5.jpg',
      'location': 'Durazno',
      'time': '4d',
      'user': 'Lucía P.',
      'likes': 45,
      'avatar': 'assets/images/avatar_mateo.png',
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF72E26E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Avistamientos recientes',
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => context.go('/map'),
              child: Row(
                children: [
                  const Text(
                    'Ver todos',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF72E26E),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF72E26E), size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _mockSightings.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _MockSightingCard(data: _mockSightings[index]),
          ),
        ),
      ],
    );
  }
}

class _MockSightingCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _MockSightingCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      width: 135,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              data['image'],
              fit: BoxFit.cover,
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.5, 0.75, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_outlined, size: 10, color: Colors.black87),
                        const SizedBox(width: 2),
                        Text(
                          data['location'],
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    data['time'],
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 9,
                        backgroundImage: AssetImage(data['avatar']),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        data['user'],
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.favorite_border_rounded, size: 12, color: Color(0xFFD4E26E)),
                      const SizedBox(width: 2),
                      Text(
                        '${data['likes']}',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
