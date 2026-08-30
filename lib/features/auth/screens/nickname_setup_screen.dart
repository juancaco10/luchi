import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/firefly_colors.dart';
import '../../../core/utils/constants.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/hardware_back_route.dart';
import '../../../widgets/ad_banner.dart';

/// Puerta de una sola vez tras el primer login: el usuario elige el apodo
/// (nombre corto, máx. 12 caracteres) con el que quiere que lo llamen en
/// el feed de avistamientos y en la app. El redirect de app.dart manda
/// aquí siempre que el perfil no tenga `hasNickname` (y el usuario no lo
/// haya omitido en esta sesión); el apodo se guarda en el backend vía
/// `PUT /me` y se usa en el saludo del home y en las tarjetas.
class NicknameSetupScreen extends ConsumerStatefulWidget {
  const NicknameSetupScreen({super.key});

  @override
  ConsumerState<NicknameSetupScreen> createState() => _NicknameSetupScreenState();
}

class _NicknameSetupScreenState extends ConsumerState<NicknameSetupScreen> {
  final _ctrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _canSave => _ctrl.text.trim().isNotEmpty;

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await ref
        .read(authProvider.notifier)
        .updateNickname(_ctrl.text.trim());
    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      // El redirect ya no volverá a mandar aquí una vez que `hasNickname`
      // sea true — basta con seguir al home.
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No se pudo guardar. Revisa tu conexión.',
              style: TextStyle(fontFamily: 'Nunito')),
          backgroundColor: context.colors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _skip() {
    // Marca la omisión solo para esta sesión (se resetea en el próximo
    // login): así se llega al home sin bucle de redirect, pero la pregunta
    // se vuelve a hacer en la próxima sesión hasta que elija un apodo.
    ref.read(authProvider.notifier).nicknamePromptOmitted = true;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return HardwareBackRoute(
      onBack: _skip,
      child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  onPressed: _skip,
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      color: context.text.bodyMedium?.color, size: 20),
                ),
              ),
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: context.firefly.glow,
                    shape: BoxShape.circle,
                    boxShadow: context.firefly.glowShadow,
                  ),
                  child: const Center(child: Text('🦋', style: TextStyle(fontSize: 44))),
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut).fadeIn(),

              const SizedBox(height: 24),

              Text(
                '¿Cómo quieres que te llamen?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: context.colors.onSurface,
                ),
              ).animate(delay: 100.ms).fadeIn(),
              const SizedBox(height: 12),

              Text(
                'Elige un apodo corto — así aparecerás en tus avistamientos '
                'y en los del resto de guardianes. Sin espacios y de '
                'máximo ${AppConstants.maxNicknameLength} caracteres.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  height: 1.5,
                  color: context.text.bodyMedium?.color,
                ),
              ).animate(delay: 150.ms).fadeIn(),

              const SizedBox(height: 32),

              TextFormField(
                controller: _ctrl,
                autofocus: true,
                maxLength: AppConstants.maxNicknameLength,
                textCapitalization: TextCapitalization.none,
                // Sin espacios: el apodo debe caber en una línea de las
                // tarjetas de avistamientos (y el backend lo valida igual).
                inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                onChanged: (_) => setState(() {}),
                onFieldSubmitted: (_) {
                  if (_canSave && !_saving) _save();
                },
                decoration: const InputDecoration(
                  hintText: 'Tu apodo',
                  helperText: 'Ej: Lucio, Nova, Rayo',
                  counterText: '',
                ),
                style: TextStyle(
                  color: context.colors.onSurface,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2, end: 0),

              const SizedBox(height: 36),

              AppButton(
                label: 'Continuar',
                onPressed: (_canSave && !_saving) ? _save : null,
                isLoading: _saving,
                icon: Icons.arrow_forward_rounded,
              ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2, end: 0),

              const SizedBox(height: 12),

              // Omitir no salva el apodo: se usará el primer nombre como
              // fallback y se volverá a preguntar en la próxima sesión.
              Center(
                child: TextButton(
                  onPressed: _saving ? null : _skip,
                  child: Text(
                    'Omitir por ahora',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.text.bodyMedium?.color,
                    ),
                  ),
                ),
              ).animate(delay: 350.ms).fadeIn(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AdBanner(),
      ),
    );
  }
}
