import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../../core/theme/firefly_colors.dart';

import '../widgets/home_header.dart';
import '../widgets/progress_card.dart';
import '../widgets/main_actions.dart';
import '../widgets/recent_sightings.dart';
import '../../../../widgets/firefly_background.dart';
import '../../../../widgets/screen_fitter.dart';

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
                    context.isDark ? Colors.black : Colors.white,
                    (context.isDark ? Colors.black : Colors.white).withValues(alpha: 0.8),
                    (context.isDark ? Colors.black : Colors.white).withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),
          ),
          // Partículas de fondo — mismo estilo ambiental que login/
          // register/onboarding, en dark y en claro (el color ya se
          // adapta solo vía context.colors).
          const FireflyBackground(count: 14, intensity: 0.35),

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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                // Los espacios y tarjetas se reducen de forma proporcional
                // en pantallas bajas — ver ScreenFitter. El scroll es solo
                // una red de seguridad: ScreenFitter calcula la escala a
                // partir del alto total de pantalla sin descontar barra de
                // estado/navegación, así que en dispositivos con poco
                // margen (o con la sección de avistamientos más alta, como
                // ahora que muestra foto) puede no alcanzar a compensar del
                // todo — sin el scroll, eso sería un overflow duro.
                child: SingleChildScrollView(
                  child: ScreenFitter(
                    naturalHeight: 720,
                    builder: (context, scale) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HomeHeader(
                          userName: userName,
                          isSmallScreen: isSmallScreen,
                          avatarUrl: user?.avatarUrl,
                        ),
                        SizedBox(height: 12 * scale),
                        const ProgressCard(),
                        SizedBox(height: 12 * scale),
                        MainActions(scale: scale),
                        SizedBox(height: 12 * scale),
                        RecentSightings(scale: scale),
                      ],
                    ),
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
