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
      final isLoggedIn = LocalStorage.instance.isLoggedIn;
      final onboardingDone = LocalStorage.instance.onboardingDone;
      final goingTo = state.matchedLocation;

      // Let splash always show
      if (goingTo == '/splash') return null;

      // Show onboarding if first time
      if (!onboardingDone && goingTo != '/onboarding') {
        return '/onboarding';
      }

      // Redirect to login if not authenticated and trying to access protected pages
      final protectedRoutes = [
        '/home', '/chapters', '/missions', '/profile', '/settings',
        '/sightings', '/map', '/game',
      ];
      final isProtected = protectedRoutes.any(
        (r) => goingTo.startsWith(r),
      );

      if (!isLoggedIn && isProtected) return '/login';
      if (isLoggedIn && (goingTo == '/login' || goingTo == '/register')) {
        return '/home';
      }

      return null;
    },
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
