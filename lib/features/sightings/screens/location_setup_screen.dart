import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/firefly_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../widgets/custom_button.dart';
import '../data/uy_places.dart';

/// Puerta antes de publicar el primer avistamiento: país y ciudad son
/// requisito porque el mapa necesita saber dónde ubicar al usuario, y
/// porque son la base del punto aleatorio que se usa cuando alguien no
/// comparte su GPS (ver sighting_form_screen.dart). Se piden una sola
/// vez — el redirect de app.dart solo manda aquí si el perfil todavía no
/// tiene `hasLocation`.
class LocationSetupScreen extends ConsumerStatefulWidget {
  const LocationSetupScreen({super.key});

  @override
  ConsumerState<LocationSetupScreen> createState() => _LocationSetupScreenState();
}

class _LocationSetupScreenState extends ConsumerState<LocationSetupScreen> {
  String _country = 'Uruguay';
  String? _uyCity;
  final _cityCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _cityCtrl.dispose();
    super.dispose();
  }

  bool get _isUruguay => _country == 'Uruguay';

  bool get _canSave => _isUruguay ? _uyCity != null : _cityCtrl.text.trim().isNotEmpty;

  Future<void> _save() async {
    final city = _isUruguay ? _uyCity! : _cityCtrl.text.trim();
    setState(() => _saving = true);
    final ok = await ref
        .read(authProvider.notifier)
        .updateLocation(country: _country, city: city);
    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      // El redirect de app.dart ya no volverá a mandar aquí una vez que
      // `hasLocation` sea true — basta con seguir a donde iba el usuario.
      context.go('/sightings/new');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: context.firefly.glow,
                    shape: BoxShape.circle,
                    boxShadow: context.firefly.glowShadow,
                  ),
                  child: const Center(child: Text('🌎', style: TextStyle(fontSize: 44))),
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut).fadeIn(),

              const SizedBox(height: 24),

              Text(
                '¿Dónde vives?',
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
                'Antes de tu primer avistamiento necesitamos saber tu país y '
                'ciudad, para poder ubicarlo en el mapa. Después, cuando '
                'registres una luciérnaga, tú decides si compartir tu '
                'ubicación exacta o dejar que marquemos un punto al azar '
                'dentro de tu ciudad — nunca vamos a mostrar dónde vives '
                'sin que tú lo elijas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  height: 1.5,
                  color: context.text.bodyMedium?.color,
                ),
              ).animate(delay: 150.ms).fadeIn(),

              const SizedBox(height: 32),

              Text(
                'País',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: context.colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _country,
                items: countries
                    .map((c) => DropdownMenuItem(value: c.name, child: Text(c.name)))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _country = v;
                    _uyCity = null;
                    _cityCtrl.clear();
                  });
                },
              ).animate(delay: 200.ms).fadeIn(),

              const SizedBox(height: 20),

              Text(
                'Ciudad',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: context.colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              if (_isUruguay)
                DropdownButtonFormField<String>(
                  initialValue: _uyCity,
                  hint: const Text('Elige tu ciudad'),
                  items: uruguayCities
                      .map((c) => DropdownMenuItem(value: c.name, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _uyCity = v),
                ).animate(delay: 250.ms).fadeIn()
              else
                TextFormField(
                  controller: _cityCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(hintText: 'Nombre de tu ciudad'),
                  style: TextStyle(color: context.colors.onSurface, fontFamily: 'Nunito'),
                ).animate(delay: 250.ms).fadeIn(),

              const SizedBox(height: 36),

              AppButton(
                label: 'Continuar',
                onPressed: (_canSave && !_saving) ? _save : null,
                isLoading: _saving,
                icon: Icons.arrow_forward_rounded,
              ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}
