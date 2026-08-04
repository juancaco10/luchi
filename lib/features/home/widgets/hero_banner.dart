import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_provider.dart';

class HeroBanner extends ConsumerWidget {
  const HeroBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E2D4A), const Color(0xFF0B161B)]
              : [const Color(0xFFE3F0F9), const Color(0xFFFFFFFF)],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : const Color(0xFF8C5209).withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Firefly Image / Illustration
          Positioned(
            right: -20,
            bottom: -10,
            child: SizedBox(
              width: 160,
              height: 160,
              child: Image.asset(
                'assets/images/jar_fireflies.png', // Temporary, ideally a cute firefly character
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Text('🪲', style: TextStyle(fontSize: 100)),
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.55,
                  child: Text(
                    'Descubre el mundo de las luciérnagas',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF1A2340),
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: Text(
                    'Aprende, juega y comparte tus avistamientos',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      color: isDark ? Colors.white70 : const Color(0xFF5A6B8A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Button
                GestureDetector(
                  onTap: () => context.go('/chapters'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF72E26E), Color(0xFF4CAF50)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF72E26E).withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Explorar ahora',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F1E19),
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF0F1E19)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
