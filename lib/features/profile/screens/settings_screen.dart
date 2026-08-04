import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/firefly_colors.dart';
import '../../../core/utils/constants.dart';
import '../../../core/storage/local_storage.dart';
import '../../../features/auth/providers/auth_provider.dart';

final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return await PackageInfo.fromPlatform();
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final packageInfo = ref.watch(packageInfoProvider);
    final versionStr = packageInfo.when(
      data: (info) => '${info.version} (${info.buildNumber})',
      loading: () => 'Cargando...',
      error: (_, __) => 'Desconocida',
    );

    return Scaffold(
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
                    onPressed: () => context.go('/profile'),
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
                        icon: Icons.email_outlined,
                        iconColor: context.colors.secondary,
                        title: 'Correo',
                        subtitle: user?.email ?? '—',
                        delay: 150,
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
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
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
                  GestureDetector(
                    onTap: () => _confirmLogout(context, ref),
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
                  ).animate(delay: 450.ms).fadeIn(),

                  const SizedBox(height: 16),

                  // ── Delete Account ─────────────────────────────
                  GestureDetector(
                    onTap: () => _confirmDeleteAccount(context, ref),
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
                  ).animate(delay: 500.ms).fadeIn(),
                ],
              ),
            ),
          ],
        ),
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

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
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
            const Text('⚠️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              '¿Borrar cuenta?',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Esta acción es permanente y se perderá todo tu progreso y avistamientos.',
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
                      final ok = await ref.read(authProvider.notifier).deleteAccount();
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
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.error,
                    ),
                    child: const Text('Borrar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context, String versionStr) {
    showDialog(
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
