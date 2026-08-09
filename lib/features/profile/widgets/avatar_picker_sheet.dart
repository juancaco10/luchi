import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/firefly_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../utils/avatar_image.dart';

/// Selector de avatar del perfil.
///
/// Deliberadamente **solo** ofrece los 18 avatares de
/// `assets/images/avatars/` — nada de cámara ni galería. No es una
/// limitación técnica temporal: es la regla ("que no pueda subir ninguna
/// desde su celular"), reforzada además en el servidor (`PUT /me` valida
/// contra la misma lista blanca), así que aunque este sheet cambiara de
/// idea algún día, el backend seguiría rechazando cualquier otra cosa.
class AvatarPickerSheet extends ConsumerStatefulWidget {
  const AvatarPickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AvatarPickerSheet(),
    );
  }

  @override
  ConsumerState<AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends ConsumerState<AvatarPickerSheet> {
  String? _saving;

  Future<void> _pick(String fileName) async {
    if (_saving != null) return;
    setState(() => _saving = fileName);
    final ok = await ref.read(authProvider.notifier).updateAvatar(fileName);
    if (!mounted) return;
    setState(() => _saving = null);
    if (ok) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el avatar. Revisa tu conexión.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final current = user?.avatarUrl;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Elige tu avatar',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: context.colors.onSurface,
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: kAvatarFileNames.length,
                itemBuilder: (context, i) {
                  final fileName = kAvatarFileNames[i];
                  final isCurrent = fileName == current;
                  final isSaving = _saving == fileName;
                  return _AvatarTile(
                    fileName: fileName,
                    selected: isCurrent,
                    loading: isSaving,
                    onTap: () => _pick(fileName),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarTile extends StatelessWidget {
  const _AvatarTile({
    required this.fileName,
    required this.selected,
    required this.loading,
    required this.onTap,
  });

  final String fileName;
  final bool selected;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? context.colors.primary : Colors.transparent,
                width: 3,
              ),
              boxShadow: selected ? context.firefly.glowShadow : null,
            ),
            padding: const EdgeInsets.all(2),
            child: ClipOval(
              child: Image.asset(
                'assets/images/avatars/$fileName',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  color: context.firefly.cardSurface,
                  child: Icon(Icons.person, color: context.colors.onSurface),
                ),
              ),
            ),
          ),
          if (loading)
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black45,
              ),
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            ),
          if (selected && !loading)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: context.colors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colors.surface, width: 2),
                ),
                child: const Icon(Icons.check, size: 12, color: Colors.black),
              ),
            ),
        ],
      ),
    );
  }
}
