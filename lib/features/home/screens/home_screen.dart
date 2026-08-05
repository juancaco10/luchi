import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../../core/theme/firefly_colors.dart';

import '../widgets/home_header.dart';
import '../widgets/progress_card.dart';
import '../widgets/main_actions.dart';
import '../widgets/recent_sightings.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userName = user?.name.split(' ').first ?? 'Explorador';
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              context.isDark ? 'assets/images/bg_home1.png' : 'assets/images/bg_home2.png',
              fit: BoxFit.cover,
            ),
          ),
          // Blur / Gradient Overlay (from bottom to top)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    context.colors.surface,
                    context.colors.surface.withValues(alpha: 0.8),
                    context.colors.surface.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),
          ),
          // Content
          // Envuelto en Positioned.fill (no bastaba con que fuera el único
          // hijo "normal" del Stack): con contenido corto, un Stack con un
          // hijo no-posicionado se encoge a la altura de ese contenido en
          // vez de llenar el body del Scaffold, dejando un hueco de color
          // liso entre el final del scroll y el menú inferior — ahí es
          // donde se veía que el fondo no llegaba abajo. Con todos los
          // hijos posicionados, el Stack pasa a ocupar siempre el alto
          // disponible completo, tenga el contenido la altura que tenga.
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HomeHeader(userName: userName, isSmallScreen: isSmallScreen),
                      const SizedBox(height: 12),
                      const ProgressCard(completedChapters: 2, totalChapters: 5), // Mock data for now
                      const SizedBox(height: 12),
                      const MainActions(),
                      const SizedBox(height: 12),
                      const RecentSightings(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
