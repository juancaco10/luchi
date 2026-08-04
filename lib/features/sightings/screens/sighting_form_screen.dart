import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/firefly_colors.dart';
import '../../../core/utils/constants.dart';
import '../providers/sightings_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/reward_overlay.dart';

class SightingFormScreen extends ConsumerStatefulWidget {
  const SightingFormScreen({super.key});

  @override
  ConsumerState<SightingFormScreen> createState() => _SightingFormScreenState();
}

class _SightingFormScreenState extends ConsumerState<SightingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  int _quantity = 1;
  double? _lat, _lng;
  bool _locating = false;
  bool _showReward = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _locating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Activa el GPS en tu dispositivo');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack('Permiso de ubicación denegado');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnack('Permiso denegado permanentemente. Actívalo en ajustes.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Blur coordinates to 3 decimals (~100m) for privacy
      final blurredLat = double.parse(pos.latitude.toStringAsFixed(3));
      final blurredLng = double.parse(pos.longitude.toStringAsFixed(3));

      setState(() {
        _lat = blurredLat;
        _lng = blurredLng;
        _locationCtrl.text =
            '${blurredLat.toStringAsFixed(3)}, ${blurredLng.toStringAsFixed(3)}';
      });
    } catch (e) {
      _showSnack('No se pudo obtener la ubicación');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }



  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_lat == null || _lng == null) {
        _showSnack('Por favor obtén o ingresa una ubicación');
        return;
      }

      final status = await ref.read(sightingsProvider.notifier).submitSighting(
            lat: _lat!,
            lng: _lng!,
            quantity: _quantity,
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
            locationName: _locationCtrl.text.trim().isEmpty
                ? null
                : _locationCtrl.text.trim(),
          );

      if (status == 'success') {
        await ref.read(authProvider.notifier).addPoints(AppConstants.pointsSighting);
        setState(() => _showReward = true);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() => _showReward = false);
          context.go('/home');
        }
      } else if (status == 'pending') {
        _showSnack('Guardado, se enviará cuando haya conexión');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) context.go('/home');
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Nunito')),
        backgroundColor: context.firefly.cardSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(sightingsProvider).isSubmitting;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.go('/home'),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: context.firefly.cardSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.firefly.cardBorder),
                            ),
                            child: Icon(Icons.arrow_back_ios_new_rounded,
                                color: context.text.bodyMedium?.color, size: 18),
                          ),
                          style: IconButton.styleFrom(padding: EdgeInsets.zero),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Registrar avistamiento',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: context.colors.onSurface,
                              ),
                            ),
                            Text(
                              '¡Tu dato es valioso para la ciencia!',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                color: context.text.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 28),

                    // Firefly emoji hero
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: context.firefly.glow,
                          shape: BoxShape.circle,
                          boxShadow: context.firefly.glowShadow,
                        ),
                        child: const Center(
                          child: Text('✨', style: TextStyle(fontSize: 52)),
                        ),
                      )
                          .animate()
                          .scale(
                            duration: 500.ms,
                            curve: Curves.elasticOut,
                            begin: const Offset(0.5, 0.5),
                          )
                          .fadeIn(),
                    ),

                    const SizedBox(height: 28),

                    // ── Location section ──────────────────────────────
                    _SectionLabel(emoji: '📍', title: 'Ubicación'),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _locationCtrl,
                            style: TextStyle(
                                color: context.colors.onSurface,
                                fontFamily: 'Nunito',
                                fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Lat, Lng o nombre del lugar',
                              prefixIcon: Icon(Icons.location_on_outlined,
                                  color: context.text.bodyMedium?.color, size: 18),
                            ),
                            onChanged: (v) {
                              // Try to parse manual lat,lng
                              final parts = v.split(',');
                              if (parts.length == 2) {
                                final lat = double.tryParse(parts[0].trim());
                                final lng = double.tryParse(parts[1].trim());
                                if (lat != null && lng != null) {
                                  if (lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
                                    _lat = double.parse(lat.toStringAsFixed(3));
                                    _lng = double.parse(lng.toStringAsFixed(3));
                                  }
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _locating ? null : _getLocation,
                          icon: _locating
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: context.colors.onPrimary,
                                  ),
                                )
                              : const Icon(Icons.gps_fixed_rounded, size: 18),
                          label: const Text('GPS'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                          ),
                        ),
                      ],
                    ).animate(delay: 100.ms).fadeIn(),

                    if (_lat != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: context.firefly.greenGlow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: context.colors.secondary, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Ubicación: ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                color: context.colors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ── Quantity section ──────────────────────────────
                    _SectionLabel(emoji: '✨', title: '¿Cuántas viste?'),
                    const SizedBox(height: 12),

                    _QuantitySelector(
                      quantity: _quantity,
                      onChanged: (v) => setState(() => _quantity = v),
                    ).animate(delay: 150.ms).fadeIn(),

                    const SizedBox(height: 24),



                    // ── Notes section ─────────────────────────────────
                    _SectionLabel(emoji: '📝', title: 'Notas (opcional)'),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      style: TextStyle(
                          color: context.colors.onSurface, fontFamily: 'Nunito'),
                      decoration: const InputDecoration(
                        hintText:
                            'Ej: Las vi cerca del río, había muchas entre los arbustos...',
                        alignLabelWithHint: true,
                      ),
                    ).animate(delay: 250.ms).fadeIn(),

                    const SizedBox(height: 32),

                    // Submit button
                    AppButton(
                      label: 'Enviar avistamiento (+${AppConstants.pointsSighting} pts)',
                      onPressed: isSubmitting ? null : _submit,
                      isLoading: isSubmitting,
                      icon: Icons.send_rounded,
                    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          if (_showReward)
            RewardOverlay(
              points: AppConstants.pointsSighting,
              message: '¡Avistamiento registrado!',
            ),
        ],
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String emoji, title;
  const _SectionLabel({required this.emoji, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: context.colors.onSurface,
          ),
        ),
      ],
    );
  }
}

// ── Quantity Selector ─────────────────────────────────────────────

class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final void Function(int) onChanged;

  const _QuantitySelector({required this.quantity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QtyButton(
          icon: Icons.remove_rounded,
          onTap: quantity > 1 ? () => onChanged(quantity - 1) : null,
        ),
        const SizedBox(width: 20),
        Column(
          children: [
            Text(
              '$quantity',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: context.colors.primary,
              ),
            ),
            Text(
              'luciérnaga(s)',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                color: context.text.bodySmall?.color,
              ),
            ),
          ],
        ),
        const SizedBox(width: 20),
        _QtyButton(
          icon: Icons.add_rounded,
          onTap: () => onChanged(quantity + 1),
        ),
        const SizedBox(width: 24),
        // Preset buttons
        Expanded(
          child: Wrap(
            spacing: 8,
            children: [5, 10, 20, 50].map((v) {
              return GestureDetector(
                onTap: () => onChanged(v),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: quantity == v
                        ? context.firefly.glow
                        : context.firefly.cardSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: quantity == v
                          ? context.colors.primary.withValues(alpha: 0.4)
                          : context.firefly.cardBorder,
                    ),
                  ),
                  child: Text(
                    '+$v',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: quantity == v
                          ? context.colors.primary
                          : context.text.bodySmall?.color,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QtyButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: onTap != null ? context.firefly.cardSurface : context.firefly.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: onTap != null ? context.firefly.cardBorder : context.firefly.cardBorder,
          ),
        ),
        child: Icon(
          icon,
          color: onTap != null ? context.colors.onSurface : context.text.bodySmall?.color,
          size: 20,
        ),
      ),
    );
  }
}
