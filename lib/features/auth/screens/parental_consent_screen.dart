import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/firefly_colors.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/firefly_background.dart';
import '../../../core/storage/local_storage.dart';

class ParentalConsentScreen extends StatefulWidget {
  const ParentalConsentScreen({super.key});

  @override
  State<ParentalConsentScreen> createState() => _ParentalConsentScreenState();
}

class _ParentalConsentScreenState extends State<ParentalConsentScreen> {
  bool _agreedToTerms = false;
  bool _saving = false;

  Future<void> _proceed() async {
    if (!_agreedToTerms || _saving) return;
    setState(() => _saving = true);
    try {
      await LocalStorage.instance.recordParentalConsent();
      await LocalStorage.instance.setOnboardingDone();
      if (!mounted) return;
      context.go('/login');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('No pudimos guardar tu confirmación. Intenta de nuevo.'),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgImage = isDark ? 'assets/images/bg1.png' : 'assets/images/bg2.png';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
      child: Scaffold(
        body: Stack(
          children: [
            // Background
            Positioned.fill(
              child: Image.asset(
                bgImage,
                fit: BoxFit.cover,
              ),
            ),
            // Gradient
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.9),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.85),
                            Colors.white.withValues(alpha: 0.4),
                          ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
            const FireflyBackground(count: 15, intensity: 0.5),

            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                            color: context.colors.primary),
                        onPressed: () => context.go('/onboarding'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Consentimiento\nParental',
                      style: context.text.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                        color: context.colors.onBackground,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                    const SizedBox(height: 32),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color:
                                context.colors.primary.withValues(alpha: 0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.privacy_tip_outlined,
                                      color: context.colors.primary, size: 28),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Aviso importante para padres o tutores',
                                      style: context.text.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: context.colors.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Para cumplir con las normas de privacidad (COPPA y GDPR-K), necesitamos tu consentimiento antes de que tu hijo/a utilice esta aplicación.',
                                style: context.text.bodyMedium
                                    ?.copyWith(height: 1.5),
                              ),
                              const SizedBox(height: 16),
                              _InfoItem(
                                icon: Icons.camera_alt_outlined,
                                title: 'Fotos y Ubicación',
                                text:
                                    'El juego permite tomar fotos de avistamientos. Eliminamos automáticamente cualquier dato GPS oculto y la información exacta de ubicación no se comparte.',
                              ),
                              _InfoItem(
                                icon: Icons.security_rounded,
                                title: 'Seguridad',
                                text:
                                    'Ninguna información personal identificable se comparte públicamente. Las fotos son moderadas.',
                              ),
                              _InfoItem(
                                icon: Icons.delete_outline_rounded,
                                title: 'Control Total',
                                text:
                                    'Puedes solicitar la eliminación de la cuenta y de todas las fotos en cualquier momento desde la configuración.',
                              ),
                            ],
                          ),
                        ),
                      )
                          .animate(delay: 150.ms)
                          .fadeIn()
                          .scale(begin: const Offset(0.95, 0.95)),
                    ),
                    const SizedBox(height: 24),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _agreedToTerms = !_agreedToTerms;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _agreedToTerms,
                                activeColor: context.colors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _agreedToTerms = value ?? false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Soy padre/tutor y doy mi consentimiento para el uso de esta aplicación.',
                                style: context.text.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate(delay: 300.ms)
                        .fadeIn()
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Continuar',
                      icon: Icons.check_circle_outline_rounded,
                      isLoading: _saving,
                      onPressed: (_agreedToTerms && !_saving) ? _proceed : null,
                    )
                        .animate(delay: 400.ms)
                        .fadeIn()
                        .slideY(begin: 0.2, end: 0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _InfoItem({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: context.colors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: context.text.bodySmall?.copyWith(
                    height: 1.4,
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
