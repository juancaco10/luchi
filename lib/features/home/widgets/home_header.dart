import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/theme_provider.dart';

class HomeHeader extends ConsumerWidget {
  final String userName;
  final bool isSmallScreen;

  const HomeHeader({
    super.key,
    required this.userName,
    required this.isSmallScreen,
  });

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
            // Logo Image
            Image.asset(
              'assets/images/luchi_logo.png',
              height: 56,
              errorBuilder: (c, e, s) => Text(
                'Luchi 🪲',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isDark ? const Color(0xFF7CFFB2) : const Color(0xFF438A3C),
                ),
              ),
            ),
            
            // Actions Right
            Row(
              children: [
                _iconButton(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, 
                  isDark, 
                  onTap: () => ref.read(themeProvider.notifier).toggleTheme()
                ),
                const SizedBox(width: 8),
                _iconButton(Icons.notifications_none_rounded, isDark),
                const SizedBox(width: 8),
                
                // Avatar
                GestureDetector(
                  onTap: () => context.go('/profile'),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? const Color(0xFF7CFFB2) : const Color(0xFF438A3C), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? const Color(0xFF7CFFB2).withValues(alpha: 0.3) : Colors.black12,
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        'assets/images/avatar_mateo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const CircleAvatar(
                          backgroundColor: Color(0xFF1E2D4A),
                          child: Text('👦', style: TextStyle(fontSize: 20)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Welcome Text
        Text(
          '¡Hola, $userName! 👋',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        
        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF7CFFB2).withValues(alpha: 0.15) : const Color(0xFF438A3C).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF7CFFB2).withValues(alpha: 0.5) : const Color(0xFF438A3C).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🛡️', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 6),
              Text(
                'Explorador Nocturno',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFF7CFFB2) : const Color(0xFF2B5B26),
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.15, end: 0);
  }

  Widget _iconButton(IconData icon, bool isDark, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            if (!isDark)
              const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Icon(icon, color: isDark ? Colors.white : const Color(0xFF2C3E50), size: 20),
      ),
    );
  }
}
