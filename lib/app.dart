import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/storage/local_storage.dart';
import 'core/network/sync_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/models/user_model.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/education/screens/chapters_list_screen.dart';
import 'features/education/screens/chapter_detail_screen.dart';
import 'features/education/screens/level_one_screen.dart';
import 'features/missions/screens/missions_screen.dart';
import 'features/missions/screens/mission_detail_screen.dart';
import 'features/sightings/screens/sighting_form_screen.dart';
import 'features/sightings/screens/map_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/profile/screens/settings_screen.dart';

class GuardianesApp extends ConsumerWidget {
  const GuardianesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep sync service alive
    ref.watch(syncServiceProvider);
    
    final themeMode = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Luchi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) => WideScreenShell(child: child),
    );
  }
}

// ── Adaptación a pantalla ancha (navegador de escritorio) ───────────
//
// El producto principal es Android: la tipografía y los targets táctiles
// se dimensionaron a propósito para un niño de 6-12 años usando el dedo.
// En un navegador de escritorio ese mismo layout se estira a todo el
// ancho de la ventana (no hay ni un solo maxWidth finito en lib/), así
// que los botones y campos acaban midiendo media pantalla.
//
// La corrección es adaptativa, no global: por debajo del breakpoint se
// devuelve el árbol intacto — móvil no cambia en absoluto —, y por
// encima se encierra en una columna del ancho de un móvil grande,
// centrada sobre el fondo del tema. Va en el `builder` del MaterialApp
// para cubrir también diálogos y SnackBars, que se pintan en el Overlay
// interno y de otro modo se escaparían del límite.
class WideScreenShell extends StatelessWidget {
  const WideScreenShell({super.key, required this.child});

  final Widget? child;

  /// Por encima de este ancho dejamos de tratar la ventana como un móvil.
  static const double wideBreakpoint = 600;

  /// Ancho de la columna en escritorio — el de un móvil grande, que es
  /// para el que está diseñada cada pantalla.
  static const double contentWidth = 480;

  @override
  Widget build(BuildContext context) {
    final content = child ?? const SizedBox.shrink();
    if (MediaQuery.sizeOf(context).width < wideBreakpoint) return content;

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: ClipRect(
          child: SizedBox(
            width: contentWidth,
            child: MediaQuery(
              // Se acota la escala en vez de fijarla: si el usuario tiene
              // fuentes grandes configuradas en el navegador, se respeta
              // hasta el techo. Fijar un valor le quitaría esa opción.
              data: MediaQuery.of(context).copyWith(
                textScaler: MediaQuery.textScalerOf(context)
                    .clamp(minScaleFactor: 0.85, maxScaleFactor: 1.1),
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Router refresh on auth changes ──────────────────────────────────
//
// GoRouter's `redirect` only re-runs on navigation by default, so logging
// out (or a token expiring mid-session) wouldn't kick the user back to
// /login until they happened to navigate again. `refreshListenable` makes
// GoRouter re-evaluate `redirect` immediately whenever auth state changes.

class _AuthRouterRefresh extends ChangeNotifier {
  _AuthRouterRefresh(Ref ref) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      notifyListeners();
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRouterRefresh(ref);
  ref.onDispose(refresh.dispose);
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      // Fuente de verdad: authProvider, no LocalStorage leído directamente.
      // Antes el redirect comprobaba LocalStorage.instance.isLoggedIn por su
      // cuenta, así que un logout disparado en otro sitio (p. ej. el
      // interceptor de red) podía dejar el storage y el authProvider
      // divergentes hasta la siguiente navegación. refreshListenable ya
      // escucha authProvider (ver _AuthRouterRefresh) para forzar una
      // re-evaluación inmediata; aquí solo hace falta leerlo.
      final isLoggedIn = ref.read(authProvider) is AuthAuthenticated;
      final onboardingDone = LocalStorage.instance.onboardingDone;
      final goingTo = state.matchedLocation;

      // Let splash always show
      if (goingTo == '/splash') return null;

      // Show onboarding if first time
      if (!onboardingDone && goingTo != '/onboarding') {
        return '/onboarding';
      }

      // Allowlist de rutas públicas en vez de una lista de rutas protegidas
      // aparte del árbol de GoRoute: si se añade una ruta nueva y se olvida
      // registrarla aquí, con la lista de protegidas quedaba pública por
      // defecto (falla insegura); con la allowlist queda protegida por
      // defecto (falla segura).
      const publicRoutes = {'/splash', '/onboarding', '/login', '/register'};
      final isPublic = publicRoutes.contains(goingTo);

      if (!isLoggedIn && !isPublic) return '/login';
      if (isLoggedIn && (goingTo == '/login' || goingTo == '/register')) {
        return '/home';
      }

      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Página no encontrada: ${state.uri}',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
    routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      pageBuilder: (context, state) => _fadeTransition(
        state,
        const SplashScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      pageBuilder: (context, state) => _fadeTransition(
        state,
        const OnboardingScreen(),
      ),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const LoginScreen(),
      ),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const RegisterScreen(),
      ),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      pageBuilder: (context, state) => _fadeTransition(
        state,
        const HomeScreen(),
      ),
    ),
    GoRoute(
      path: '/chapters',
      name: 'chapters',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const ChaptersListScreen(),
      ),
    ),
    GoRoute(
      path: '/chapters/:id',
      name: 'chapter-detail',
      pageBuilder: (context, state) => _slideTransition(
        state,
        ChapterDetailScreen(chapterId: state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/game/level-1',
      name: 'game-level-1',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const LevelOneScreen(),
      ),
    ),
    GoRoute(
      path: '/missions',
      name: 'missions',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const MissionsScreen(),
      ),
    ),
    GoRoute(
      path: '/missions/:id',
      name: 'mission-detail',
      pageBuilder: (context, state) => _slideTransition(
        state,
        MissionDetailScreen(missionId: state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const ProfileScreen(),
      ),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const SettingsScreen(),
      ),
    ),
    GoRoute(
      path: '/sightings/new',
      name: 'sighting-form',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const SightingFormScreen(),
      ),
    ),
    GoRoute(
      path: '/map',
      name: 'map',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const MapScreen(),
      ),
    ),
    ],
  );
});

// ── Page Transitions ──────────────────────────────────────────────

CustomTransitionPage<void> _fadeTransition(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
        child: child,
      );
    },
  );
}

CustomTransitionPage<void> _slideTransition(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}
