import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/firefly_colors.dart';
import '../../../core/utils/constants.dart';
import '../models/sighting_model.dart';
import '../providers/sightings_provider.dart';
import '../utils/sighting_geocoding.dart';
import '../utils/nsfw_filter.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/reward_overlay.dart';

/// Crea un avistamiento nuevo, o edita uno existente si se pasa
/// [sightingId] — mismo formulario para ambos, sin duplicar la UI.
/// En modo edición no se ofrecen puntos: no es un logro nuevo.
class SightingFormScreen extends ConsumerStatefulWidget {
  final int? sightingId;
  const SightingFormScreen({super.key, this.sightingId});

  @override
  ConsumerState<SightingFormScreen> createState() => _SightingFormScreenState();
}

class _SightingFormScreenState extends ConsumerState<SightingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();

  int _quantity = 1;
  double? _lat, _lng;
  String? _locationName;
  bool _showReward = false;
  bool _prefilled = false;
  bool _resolvingLocation = false;

  // true por defecto: compartir la ubicación exacta es la opción
  // destacada, pero el usuario puede apagarla y el punto se marca al azar
  // dentro de su ciudad — ver PRIVACY.md, nunca se dispara el permiso
  // nativo sin esta explicación visible primero.
  bool _shareGps = true;

  // Foto: `_pickedPhoto` es el archivo local recién elegido (aún no
  // subido); `_existingPhotoUrl` es la que ya vive en el servidor (modo
  // edición) o la que se acaba de subir.
  File? _pickedPhoto;
  String? _existingPhotoUrl;
  bool _uploadingPhoto = false;
  bool _checkingPhoto = false;

  bool get _isEditing => widget.sightingId != null;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  /// Editar no vuelve a tocar la ubicación (no se re-pide GPS ni se
  /// recalcula el punto aleatorio) — se conservan tal cual la coordenada y
  /// el nombre que ya tenía el avistamiento.
  void _prefillFrom(SightingModel s) {
    if (_prefilled) return;
    _prefilled = true;
    _quantity = s.quantity;
    _lat = s.lat;
    _lng = s.lng;
    _locationName = s.locationName;
    _notesCtrl.text = s.notes ?? '';
    _existingPhotoUrl = s.photoUrl;
  }

  /// Resuelve dónde cae el marcador de un avistamiento nuevo: con el GPS
  /// si el usuario lo comparte (y el permiso se concede), o un punto al
  /// azar dentro de la ciudad de su perfil en cualquier otro caso — sin
  /// permiso, denegado, GPS apagado por el usuario, o el propio GPS falla.
  /// Nunca bloquea el envío: siempre hay una alternativa válida.
  Future<void> _resolveLocation() async {
    final user = ref.read(currentUserProvider);
    // El redirect de app.dart no deja llegar aquí sin país/ciudad, pero
    // por robustez (deep link, estado inconsistente) se cubre igual.
    final country = user?.country;
    final city = user?.city;
    if (country == null || city == null) {
      _lat = unresolvedLat;
      _lng = unresolvedLng;
      _locationName = null;
      return;
    }

    _locationName = '$city, $country';

    final cityCoords = await resolveProfileCityCoordinates(country: country, city: city);
    if (cityCoords == null) {
      // Sin conexión y el país no tiene lista fija (no es Uruguay) — no
      // hay de dónde sacar ni el punto exacto ni uno aleatorio todavía.
      _lat = unresolvedLat;
      _lng = unresolvedLng;
      return;
    }

    if (_shareGps) {
      final exact = await _tryGetGpsPosition();
      if (exact != null) {
        _lat = exact.lat;
        _lng = exact.lng;
        return;
      }
    }

    final random = randomPointNear(cityCoords.lat, cityCoords.lng, radiusKm: 3);
    _lat = random.lat;
    _lng = random.lng;
  }

  Future<({double lat, double lng})?> _tryGetGpsPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      // Difuminado a 3 decimales (~100 m) antes de que la coordenada salga
      // del dispositivo — igual criterio que el resto de la app.
      return (
        lat: double.parse(pos.latitude.toStringAsFixed(3)),
        lng: double.parse(pos.longitude.toStringAsFixed(3)),
      );
    } catch (_) {
      return null;
    }
  }

  /// PRIVACY.md exige una explicación en pantalla ANTES de disparar el
  /// diálogo nativo de permiso de cámara/galería, en lenguaje apto para
  /// niños — no basta con dejar que el sistema operativo lo pida solo.
  Future<void> _choosePhotoSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📸 Foto de tu avistamiento',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: context.colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Usaremos tu cámara o tus fotos solo para esta imagen. Es opcional.',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  color: context.text.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar foto', style: TextStyle(fontFamily: 'Nunito')),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir de la galería', style: TextStyle(fontFamily: 'Nunito')),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      // `imageQuality`/`maxWidth` re-codifican la imagen al elegirla, lo
      // que ya descarta el EXIF (ubicación, dispositivo) como primera
      // capa — el servidor la vuelve a recodificar como segunda capa.
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked == null || !mounted) return;

      final file = File(picked.path);

      // Filtro de contenido on-device (nunca sale del teléfono para esta
      // comprobación) antes de aceptar la foto — primera barrera, no un
      // moderador perfecto, pero bloquea lo obvio sin subir nada.
      setState(() => _checkingPhoto = true);
      final safe = await isPhotoSafe(file);
      if (!mounted) return;
      setState(() => _checkingPhoto = false);

      if (!safe) {
        _showSnack('Esta foto no se puede usar. Elige otra foto de luciérnagas 🌿');
        return;
      }

      setState(() {
        _pickedPhoto = file;
        _existingPhotoUrl = null; // se reemplaza la que hubiera
      });
    } catch (_) {
      if (mounted) _showSnack('No se pudo acceder a la cámara o galería');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // En modo edición la ubicación ya viene de `_prefillFrom` y no se
    // vuelve a tocar. Solo al crear se resuelve GPS/punto aleatorio —
    // aquí es también donde, si `_shareGps` está activo, se dispara el
    // permiso nativo (la explicación ya estuvo visible en pantalla antes).
    if (!_isEditing) {
      setState(() => _resolvingLocation = true);
      await _resolveLocation();
      if (!mounted) return;
      setState(() => _resolvingLocation = false);

      if (isUnresolvedCoordinate(_lat ?? 0, _lng ?? 0)) {
        _showSnack('No pudimos ubicar tu ciudad ahora mismo. '
            'Se completará automáticamente cuando tengas conexión.');
      }
    }

    final locationName = _locationName ?? '';

    // Subir la foto primero si hay una nueva. Requiere conexión: si falla
    // (sin red), el avistamiento se guarda igualmente sin foto y se avisa
    // — no bloqueamos el registro por esto.
    String? photoUrl = _existingPhotoUrl;
    if (_pickedPhoto != null) {
      setState(() => _uploadingPhoto = true);
      photoUrl = await ref.read(sightingsProvider.notifier).uploadPhoto(_pickedPhoto!);
      if (mounted) setState(() => _uploadingPhoto = false);
      if (photoUrl == null && mounted) {
        _showSnack('No se pudo subir la foto (sin conexión). Se guardará sin foto.');
      }
    }

    final notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();

    if (_isEditing) {
      final ok = await ref.read(sightingsProvider.notifier).updateSighting(
            id: widget.sightingId!,
            lat: _lat!,
            lng: _lng!,
            quantity: _quantity,
            notes: notes,
            photoUrl: photoUrl,
            locationName: locationName,
          );
      if (!mounted) return;
      if (ok) {
        context.go('/sightings');
      } else {
        final error = ref.read(sightingsProvider).error;
        _showSnack(error ?? 'No se pudo guardar el cambio');
      }
      return;
    }

    final status = await ref.read(sightingsProvider.notifier).submitSighting(
          lat: _lat!,
          lng: _lng!,
          quantity: _quantity,
          notes: notes,
          photoUrl: photoUrl,
          locationName: locationName,
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

  String _profileCityLabel() {
    final user = ref.read(currentUserProvider);
    if (user == null || !user.hasLocation) return 'tu ciudad';
    return '${user.city}, ${user.country}';
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
    if (_isEditing) {
      final existing = ref.watch(sightingByIdProvider(widget.sightingId!));
      if (existing != null) _prefillFrom(existing);
    }

    final isSubmitting = ref.watch(sightingsProvider).isSubmitting;
    final busy = isSubmitting || _uploadingPhoto || _checkingPhoto || _resolvingLocation;

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
                          onPressed: () => context.go(_isEditing ? '/sightings' : '/home'),
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
                              _isEditing ? 'Editar avistamiento' : 'Registrar avistamiento',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: context.colors.onSurface,
                              ),
                            ),
                            Text(
                              _isEditing
                                  ? 'Corrige los datos que necesites'
                                  : '¡Tu dato es valioso para la ciencia!',
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

                    // ── Photo section ──────────────────────────────────
                    _SectionLabel(emoji: '📸', title: 'Foto (opcional)'),
                    const SizedBox(height: 10),
                    _PhotoPicker(
                      pickedFile: _pickedPhoto,
                      existingUrl: _existingPhotoUrl,
                      isUploading: _uploadingPhoto,
                      isChecking: _checkingPhoto,
                      onTap: busy ? null : _choosePhotoSource,
                      onRemove: () => setState(() {
                        _pickedPhoto = null;
                        _existingPhotoUrl = null;
                      }),
                    ).animate(delay: 50.ms).fadeIn(),

                    const SizedBox(height: 24),

                    // ── Location section ──────────────────────────────
                    // Solo al crear: en edición la ubicación no se toca
                    // (ver _prefillFrom).
                    if (!_isEditing) ...[
                      _SectionLabel(emoji: '📍', title: 'Ubicación'),
                      const SizedBox(height: 10),
                      _LocationCard(
                        cityLabel: _profileCityLabel(),
                        shareGps: _shareGps,
                        resolving: _resolvingLocation,
                        onChanged: busy ? null : (v) => setState(() => _shareGps = v),
                      ).animate(delay: 100.ms).fadeIn(),
                      const SizedBox(height: 24),
                    ],

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
                      label: _isEditing
                          ? 'Guardar cambios'
                          : 'Enviar avistamiento (+${AppConstants.pointsSighting} pts)',
                      onPressed: busy ? null : _submit,
                      isLoading: busy,
                      icon: _isEditing ? Icons.save_rounded : Icons.send_rounded,
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

// ── Photo Picker ─────────────────────────────────────────────────

class _PhotoPicker extends StatelessWidget {
  final File? pickedFile;
  final String? existingUrl;
  final bool isUploading;
  final bool isChecking;
  final VoidCallback? onTap;
  final VoidCallback onRemove;

  const _PhotoPicker({
    required this.pickedFile,
    required this.existingUrl,
    required this.isUploading,
    required this.isChecking,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = pickedFile != null || existingUrl != null;

    if (!hasPhoto) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: context.firefly.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.firefly.cardBorder),
          ),
          child: Center(
            child: isChecking
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Revisando la foto...',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.text.bodyMedium?.color,
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_a_photo_outlined, color: context.text.bodyMedium?.color, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        'Agregar una foto',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.text.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: double.infinity,
              height: 160,
              child: pickedFile != null
                  ? Image.file(pickedFile!, fit: BoxFit.cover)
                  : Image.network(
                      existingUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) => progress == null
                          ? child
                          : const Center(child: CircularProgressIndicator()),
                      errorBuilder: (context, error, stack) => Container(
                        color: context.firefly.cardSurface,
                        child: Icon(Icons.broken_image_outlined,
                            color: context.text.bodyMedium?.color),
                      ),
                    ),
            ),
          ),
        ),
        if (isUploading)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Location Card ─────────────────────────────────────────────────
//
// PRIVACY.md exige explicar en pantalla ANTES de disparar el permiso
// nativo de ubicación — esta tarjeta es esa explicación, siempre visible
// antes de que el interruptor esté en "sí" y se envíe el formulario (que
// es cuando realmente se pide el permiso, en _tryGetGpsPosition).

class _LocationCard extends StatelessWidget {
  final String cityLabel;
  final bool shareGps;
  final bool resolving;
  final ValueChanged<bool>? onChanged;

  const _LocationCard({
    required this.cityLabel,
    required this.shareGps,
    required this.resolving,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.firefly.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.firefly.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu avistamiento se marcará en $cityLabel.',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Si compartes tu ubicación, lo marcamos en el punto exacto '
            'donde viste la luciérnaga. Si no, ponemos un punto al azar '
            'dentro de tu ciudad. Tú eliges.',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              height: 1.5,
              color: context.text.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.my_location_rounded, size: 18, color: context.colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Compartir mi ubicación exacta',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.colors.onSurface,
                  ),
                ),
              ),
              if (resolving)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Switch(value: shareGps, onChanged: onChanged),
            ],
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
