import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/firefly_colors.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/firefly_background.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingPage> _pages = [
    _OnboardingPage(
      emoji: '🌙',
      title: 'Bienvenido, Guardián',
      subtitle:
          'Las luciérnagas son mágicas y necesitan tu ayuda. Juntos podemos proteger su hogar.',
      gradient: [Color(0xFF1A2440), Color(0xFF0B0F1A)],
    ),
    _OnboardingPage(
      emoji: '📖',
      title: 'Aprende su historia',
      subtitle:
          'Descubre capítulos llenos de curiosidades sobre las luciérnagas y el ecosistema nocturno.',
      gradient: [Color(0xFF0F2030), Color(0xFF0B0F1A)],
    ),
    _OnboardingPage(
      emoji: '🌿',
      title: 'Aprende jugando',
      subtitle:
          'Gana puntos respondiendo quizzes y demuestra lo que has aprendido sobre la conservación de las luciérnagas.',
      gradient: [Color(0xFF0A2010), Color(0xFF0B0F1A)],
    ),
    _OnboardingPage(
      emoji: '✨',
      title: 'Registra avistamientos',
      subtitle:
          'Anota dónde viste luciérnagas. Tu información ayuda a científicos a mapear su hábitat.',
      gradient: [Color(0xFF1A1530), Color(0xFF0B0F1A)],
    ),
  ];

  List<Color> _accentColors(BuildContext context) => [
        context.colors.primary,
        context.firefly.accent,
        context.colors.secondary,
        context.colors.primary,
      ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    if (!mounted) return;
    context.go('/onboarding/consent');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgImage = isDark ? 'assets/images/bg1.png' : 'assets/images/bg2.png';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Fondo
          Positioned.fill(
            child: Image.asset(
              bgImage,
              fit: BoxFit.cover,
            ),
          ),

          // Page content
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _OnboardingPageWidget(
                page: _pages[index],
                accentColor: _accentColors(context)[index],
              );
            },
          ),

          // Partículas de fondo, siempre presentes en las 4 páginas —
          // por encima del degradado de cada página (PageView, opaco),
          // por debajo de la barra de controles inferior. Mismo patrón
          // que login/register: son de fondo ambiental, no interactivas
          // (IgnorePointer dentro del propio widget).
          const FireflyBackground(count: 18, intensity: 0.5),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 48),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xE00B0F1A)],
                ),
              ),
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _currentPage ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _currentPage
                              ? _accentColors(context)[_currentPage]
                              : context.firefly.cardBorder,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Action button
                  AppButton(
                    label: _currentPage == _pages.length - 1
                        ? '¡Empezar mi aventura!'
                        : 'Siguiente',
                    onPressed: _nextPage,
                    gradient: LinearGradient(
                      colors: [
                        _accentColors(context)[_currentPage],
                        _accentColors(context)[_currentPage].withOpacity(0.7),
                      ],
                    ),
                  ),

                  if (_currentPage < _pages.length - 1) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        'Saltar',
                        style: TextStyle(color: context.text.bodySmall?.color),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single Onboarding Page ────────────────────────────────────────

class _OnboardingPageWidget extends StatelessWidget {
  final _OnboardingPage page;
  final Color accentColor;

  const _OnboardingPageWidget({required this.page, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            page.gradient[0].withValues(alpha: 0.7),
            page.gradient[1].withValues(alpha: 0.9),
          ],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),

                      // Emoji with glow
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor.withOpacity(0.1),
                          border: Border.all(
                            color: accentColor.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.25),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            page.emoji,
                            style: const TextStyle(fontSize: 64),
                          ),
                        ),
                      ).animate().scale(
                            duration: 600.ms,
                            curve: Curves.elasticOut,
                            begin: const Offset(0.5, 0.5),
                          ),

                      const SizedBox(height: 32),

                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                      )
                          .animate(delay: 200.ms)
                          .fadeIn()
                          .slideY(begin: 0.3, end: 0),

                      const SizedBox(height: 16),

                      Text(
                        page.subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: context.text.bodyMedium?.color,
                          height: 1.5,
                        ),
                      )
                          .animate(delay: 350.ms)
                          .fadeIn()
                          .slideY(begin: 0.3, end: 0),

                      // Responsive space for bottom controls bar
                      const SizedBox(height: 160),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Data Model ────────────────────────────────────────────────────

class _OnboardingPage {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}
