import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/firefly_colors.dart';
import '../../../core/utils/constants.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../widgets/ad_banner.dart';
import '../../../widgets/hardware_back_route.dart';

final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return await PackageInfo.fromPlatform();
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // No hay indicador de progreso visible mientras `deleteAccount()` está
  // en vuelo (el bottom sheet ya se cerró en ese momento), así que sin
  // este guard un segundo tap en "Borrar mi cuenta" podía arrancar un
  // segundo flujo de borrado en paralelo. Estático porque esta pantalla
  // no tiene estado propio (ConsumerWidget) y solo existe una instancia
  // visible a la vez.
  static bool _deletingAccount = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final packageInfo = ref.watch(packageInfoProvider);
    final versionStr = packageInfo.when(
      data: (info) => '${info.version} (${info.buildNumber})',
      loading: () => 'Cargando...',
      error: (_, __) => 'Desconocida',
    );

    return HardwareBackRoute(
      onBack: () => context.go('/home'),
      child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/home'),
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: context.text.bodyMedium?.color, size: 20),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Configuración',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: context.colors.onSurface,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                children: [
                  // ── Account section ────────────────────────────
                  _SettingsSection(
                    title: 'Cuenta',
                    children: [
                      _SettingsTile(
                        icon: Icons.person_outline_rounded,
                        iconColor: context.firefly.accent,
                        title: 'Nombre',
                        subtitle: user?.name ?? '—',
                        delay: 100,
                      ),
                      _SettingsTile(
                        icon: Icons.tag_rounded,
                        iconColor: context.firefly.accent,
                        title: 'Apodo',
                        subtitle: (user?.hasNickname ?? false)
                            ? user!.nickname!
                            : 'Sin configurar',
                        delay: 125,
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showNicknameSheet(context, ref),
                      ),
                      _SettingsTile(
                        icon: Icons.email_outlined,
                        iconColor: context.colors.secondary,
                        title: 'Correo',
                        subtitle: user?.email ?? '—',
                        delay: 150,
                      ),
                      _SettingsTile(
                        icon: Icons.place_outlined,
                        iconColor: context.colors.primary,
                        title: 'País y ciudad',
                        subtitle: (user?.hasLocation ?? false)
                            ? '${user!.city}, ${user.country}'
                            : 'Sin configurar',
                        delay: 175,
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.go('/sightings/location-setup'),
                      ),
                    ],
                  ),



                  // ── Appearance section ─────────────────────────
                  const SizedBox(height: 20),
                  _SettingsSection(
                    title: 'Apariencia',
                    children: [
                      _SettingsTile(
                        icon: context.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        iconColor: context.colors.primary,
                        title: 'Tema oscuro',
                        subtitle: context.isDark ? 'Activado' : 'Desactivado',
                        delay: 200,
                        trailing: Switch(
                          value: context.isDark,
                          onChanged: (val) => ref.read(themeProvider.notifier).toggleTheme(),
                          activeColor: context.colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── About section ──────────────────────────────
                  _SettingsSection(
                    title: 'Acerca de',
                    children: [
                      _SettingsTile(
                        icon: Icons.info_outline_rounded,
                        iconColor: context.firefly.accent,
                        title: 'Versión',
                        subtitle: versionStr,
                        delay: 300,
                      ),
                      _SettingsTile(
                        icon: Icons.privacy_tip_outlined,
                        iconColor: context.text.bodySmall?.color ?? Colors.grey,
                        title: 'Política de privacidad',
                        subtitle: 'Cómo protegemos tus datos',
                        delay: 350,
                        onTap: () async {
                          final uri = Uri.parse(
                            AppConstants.baseUrl.replaceAll(RegExp(r'/api/?$'), '/privacidad.html'),
                          );
                          final opened = await canLaunchUrl(uri) && await launchUrl(uri);
                          if (!opened && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No se pudo abrir la política de privacidad.'),
                              ),
                            );
                          }
                        },
                      ),
                      _SettingsTile(
                        icon: Icons.favorite_outline_rounded,
                        iconColor: context.colors.error,
                        title: 'Sobre el proyecto',
                        subtitle:
                            'Guardianes de las Luciérnagas — Proyecto educativo ambiental',
                        delay: 400,
                        onTap: () => _showAboutDialog(context, versionStr),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Logout ─────────────────────────────────────
                  Material(
                    color: Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadius),
                    child: InkWell(
                    onTap: () => _confirmLogout(context, ref),
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadius),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.colors.error.withValues(alpha: 0.07),
                        borderRadius:
                            BorderRadius.circular(AppConstants.borderRadius),
                        border: Border.all(
                            color: context.colors.error.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded,
                              color: context.colors.error, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Cerrar sesión',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: context.colors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ),
                  ).animate(delay: 450.ms).fadeIn(),

                  const SizedBox(height: 16),

                  // ── Delete Account ─────────────────────────────
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    child: InkWell(
                    onTap: () => _confirmDeleteAccount(context, ref),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                        border: Border.all(color: context.colors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_forever_rounded, color: context.colors.error, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Borrar mi cuenta',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: context.colors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ),
                  ).animate(delay: 500.ms).fadeIn(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AdBanner(),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👋', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              '¿Cerrar sesión?',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tu progreso está guardado de forma segura.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: context.text.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.error,
                    ),
                    child: const Text('Salir'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Paso 1: advertencia + campo de texto que exige escribir "ELIMINAR".
  /// No borra nada aquí — solo habilita pasar al paso 2 para evitar que un
  /// toque accidental (o un niño explorando la app) llegue a un borrado real.
  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    if (_deletingAccount) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => _DeleteAccountStep1Sheet(
        onConfirmed: () {
          Navigator.pop(sheetContext);
          _finalConfirmDeleteAccount(context, ref);
        },
      ),
    );
  }

  /// Paso 2: última confirmación antes de ejecutar el borrado real.
  void _finalConfirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🚨', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Última confirmación',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Al continuar, tu cuenta se borrará ahora mismo y no podrás recuperarla.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: context.text.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_deletingAccount) return;
                      _deletingAccount = true;
                      Navigator.pop(context);
                      try {
                        final ok =
                            await ref.read(authProvider.notifier).deleteAccount();
                        if (context.mounted) {
                          if (ok) {
                            context.go('/login');
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Error al borrar la cuenta. Verifica tu conexión.', style: TextStyle(fontFamily: 'Nunito')),
                                backgroundColor: context.colors.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        }
                      } finally {
                        _deletingAccount = false;
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.error,
                    ),
                    child: const Text(
                      'Borrar\ndefinitivamente',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Edita el apodo desde ajustes. Misma validación que en la pantalla de
  /// primer login (nickname_setup_screen.dart): máximo 12 caracteres y sin
  /// espacios — es lo que se muestra en las tarjetas de avistamientos.
  void _showNicknameSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => _NicknameSheet(
        current: ref.read(currentUserProvider)?.nickname,
        onChanged: (newNickname) async {
          return await ref.read(authProvider.notifier).updateNickname(newNickname);
        },
      ),
    );
  }

  void _showAboutDialog(BuildContext context, String versionStr) {    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.cardRadius)),
        title: Text(
          'Guardianes de las Luciérnagas 🪲',
          style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              color: context.colors.onSurface,
              fontSize: 18),
        ),
        content: Text(
          'Versión $versionStr\n\nUna aplicación educativa para niños sobre la conservación de las luciérnagas y el cuidado del medio ambiente nocturno.\n\nDesarrollada con ❤️ para un futuro más luminoso.',
          style: TextStyle(
              fontFamily: 'Nunito',
              color: context.text.bodyMedium?.color,
              fontSize: 14,
              height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

// ── Delete Account — Step 1 sheet ───────────────────────────────────

class _DeleteAccountStep1Sheet extends StatefulWidget {
  const _DeleteAccountStep1Sheet({required this.onConfirmed});

  final VoidCallback onConfirmed;

  @override
  State<_DeleteAccountStep1Sheet> createState() => _DeleteAccountStep1SheetState();
}

class _DeleteAccountStep1SheetState extends State<_DeleteAccountStep1Sheet> {
  static const _kConfirmWord = 'ELIMINAR';
  final _controller = TextEditingController();
  bool _matches = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: Text('⚠️', style: TextStyle(fontSize: 48))),
          const SizedBox(height: 16),
          Text(
            '¿Borrar cuenta?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Esta acción es permanente. Se eliminarán tu progreso, puntos, insignias, capítulos completados y todas tus fotos y avistamientos. No podrás recuperarlos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              color: context.text.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Para continuar, escribe ELIMINAR:',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              color: context.colors.onSurface,
            ),
            decoration: InputDecoration(
              hintText: _kConfirmWord,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
            ),
            onChanged: (value) {
              final matches = value.trim().toUpperCase() == _kConfirmWord;
              if (matches != _matches) setState(() => _matches = matches);
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _matches ? widget.onConfirmed : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.error,
                  ),
                  child: const Text('Continuar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Nickname Sheet ────────────────────────────────────────────────

class _NicknameSheet extends ConsumerStatefulWidget {
  const _NicknameSheet({required this.current, required this.onChanged});

  final String? current;
  final Future<bool> Function(String) onChanged;

  @override
  ConsumerState<_NicknameSheet> createState() => _NicknameSheetState();
}

class _NicknameSheetState extends ConsumerState<_NicknameSheet> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.current ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _canSave => _ctrl.text.trim().isNotEmpty;

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await widget.onChanged(_ctrl.text.trim());
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No se pudo guardar el apodo. Revisa tu conexión.',
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: Text('🦋', style: TextStyle(fontSize: 44))),
          const SizedBox(height: 12),
          Text(
            'Tu apodo',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Así te llamarán en tus avistamientos y en el feed. Máximo '
            '${AppConstants.maxNicknameLength} caracteres, sin espacios.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              color: context.text.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _ctrl,
            autofocus: true,
            maxLength: AppConstants.maxNicknameLength,
            textCapitalization: TextCapitalization.none,
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
            onChanged: (_) => setState(() {}),
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              color: context.colors.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Tu apodo',
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: (_canSave && !_saving) ? _save : null,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Settings Section ──────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: context.text.bodySmall?.color,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: context.firefly.cardSurface,
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            border: Border.all(color: context.firefly.cardBorder),
          ),
          child: Column(
            children: children.asMap().entries.map((e) {
              final isLast = e.key == children.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 56,
                      color: Theme.of(context).dividerTheme.color,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Settings Tile ─────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final int delay;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.delay,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.colors.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: context.text.bodySmall?.color,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (trailing == null && onTap != null)
              Icon(Icons.arrow_forward_ios_rounded,
                  color: context.text.bodySmall?.color, size: 14),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: delay)).fadeIn().slideX(begin: 0.05, end: 0);
  }
}
