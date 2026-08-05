import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/firefly_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../data/google_auth_service.dart';
import '../widgets/google_sign_in_button.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/firefly_background.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _googleLoading = false;
  StreamSubscription<String>? _googleWebSub;

  @override
  void initState() {
    super.initState();
    GoogleAuthService.instance.ensureInitialized();
    if (kIsWeb) {
      // En web el idToken no llega como resultado de un tap propio: el
      // usuario interactúa con el botón que Google renderiza dentro de
      // GoogleSignInButton, y el resultado se escucha aquí.
      _googleWebSub = GoogleAuthService.instance.idTokenOnWebSignIn.listen(
        _submitGoogleIdToken,
        onError: (Object e) => _mostrarErrorGoogle(),
      );
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _googleWebSub?.cancel();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier).login(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );
    if (ok && mounted) {
      context.go('/home');
    }
  }

  // ── Google ─────────────────────────────────────────────────────
  // Android/iOS/desktop: authenticate() es una llamada directa. En web el
  // botón se renderiza inline más abajo y el resultado llega por el
  // stream suscrito en initState — este método solo cubre el primer caso.
  Future<void> _loginConGoogle() async {
    setState(() => _googleLoading = true);
    try {
      final idToken = await GoogleAuthService.instance.signInInteractive();
      if (idToken == null) return; // el usuario canceló el selector
      await _submitGoogleIdToken(idToken);
    } catch (_) {
      _mostrarErrorGoogle();
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _submitGoogleIdToken(String idToken) async {
    final ok =
        await ref.read(authProvider.notifier).loginConGoogle(idToken);
    if (ok && mounted) context.go('/home');
  }

  void _mostrarErrorGoogle() {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text(
          'No se pudo conectar con Google. Inténtalo de nuevo.',
          style: TextStyle(fontFamily: 'Nunito'),
        ),
        behavior: SnackBarBehavior.floating,
      ));
  }

  // ── Accesos aún sin backend ──────────────────────────────────────
  // El servidor (backend/api/routes/users.php) expone POST /register,
  // POST /login, POST /auth/google, GET /me y DELETE /me. Faltan invitado
  // y recuperación de contraseña; la UI existe ya para no rehacerla luego.

  Future<void> _entrarComoInvitado() async {
    final ok = await ref.read(authProvider.notifier).loginInvitado();
    if (ok && mounted) context.go('/home');
  }

  // TODO: requiere POST /forgot-password + envío de correo desde el backend.
  void _recuperarPassword() => _proximamente('Recuperar contraseña');

  void _proximamente(String queFalta) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$queFalta estará disponible pronto',
            style: const TextStyle(fontFamily: 'Nunito'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;
    final error = authState is AuthError ? authState.message : null;

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
            // Fondo
            Positioned.fill(
              child: Image.asset(
                bgImage,
                fit: BoxFit.cover,
              ),
            ),
            // Gradiente para aclarar/oscurecer
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.85),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.85),
                            Colors.white.withValues(alpha: 0.2),
                          ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
            const FireflyBackground(count: 22, intensity: 0.6),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 28, right: 28, top: 4, bottom: 24),
                child: Column(
                  children: [
                    // ── Logo ──────────────────────────────────────────
                    // Misma imagen e igual tratamiento (recorte redondeado +
                    // brillo) que el splash, para que icono, splash y esta
                    // primera pantalla se vean como una sola marca.
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.asset(
                          'assets/images/logo_luchi.png',
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => Text(
                            'Luchi',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: context.colors.primary,
                            ),
                          ),
                        ),
                      ),
                  ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.9, 0.9)),

                  const SizedBox(height: 16),

                  Text(
                    'Bienvenido de nuevo',
                    textAlign: TextAlign.center,
                    style: context.text.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Aprende jugando',
                    style: context.text.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 56,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.colors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Botones Rápidos ─────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: kIsWeb
                            ? Center(child: buildWebGoogleButton())
                                .animate(delay: 100.ms)
                                .fadeIn()
                                .slideY(begin: 0.15, end: 0)
                            : _OutlinedAction(
                                label: _googleLoading ? '...' : 'Google',
                                onTap: _googleLoading ? null : _loginConGoogle,
                                leading: _googleLoading
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: context.colors.primary,
                                        ),
                                      )
                                    : Text(
                                        'G',
                                        style: TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: context.colors.primary,
                                        ),
                                      ),
                                filled: true,
                              ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.15, end: 0),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _OutlinedAction(
                          label: 'Invitado',
                          onTap: _entrarComoInvitado,
                          leading: Icon(Icons.person_outline_rounded,
                              size: 20, color: context.colors.primary),
                        ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.15, end: 0),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Separador ─────────────────────────────────────
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('o continúa con tu correo',
                            style: context.text.bodySmall),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Banner de error del backend ───────────────────
                  if (error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.colors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.colors.error.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded,
                              color: context.colors.error, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              error,
                              style: TextStyle(
                                color: context.colors.error,
                                fontFamily: 'Nunito',
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().shake(),
                    const SizedBox(height: 20),
                  ],

                  // ── Formulario ────────────────────────────────────
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(
                              color: context.colors.onSurface, fontFamily: 'Nunito'),
                          decoration: InputDecoration(
                            labelText: 'Correo electrónico',
                            hintText: 'ejemplo@correo.com',
                            prefixIcon: Icon(Icons.email_outlined,
                                color: context.colors.primary, size: 20),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Campo requerido';
                            if (!v.contains('@')) return 'Correo inválido';
                            return null;
                          },
                        ).animate(delay: 200.ms).fadeIn().slideX(begin: -0.1, end: 0),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          style: TextStyle(
                              color: context.colors.onSurface, fontFamily: 'Nunito'),
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: Icon(Icons.lock_outline_rounded,
                                color: context.colors.primary, size: 20),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Mostrar contraseña'
                                  : 'Ocultar contraseña',
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: context.text.bodySmall?.color,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Campo requerido';
                            if (v.length < 6) return 'Mínimo 6 caracteres';
                            return null;
                          },
                        ).animate(delay: 250.ms).fadeIn().slideX(begin: -0.1, end: 0),

                        const SizedBox(height: 8),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _recuperarPassword,
                            child: Text(
                              '¿Olvidaste tu contraseña?',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: context.colors.primary,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        AppButton(
                          label: 'Iniciar sesión',
                          icon: Icons.arrow_forward_rounded,
                          onPressed: isLoading ? null : _login,
                          isLoading: isLoading,
                        ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '¿No tienes cuenta? ',
                              style: context.text.bodyMedium,
                            ),
                            TextButton(
                              onPressed: () => context.go('/register'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Regístrate',
                                style: TextStyle(
                                  color: context.colors.primary,
                                  fontFamily: 'Nunito',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ).animate(delay: 400.ms).fadeIn(),
                      ],
                    ),
                  ),
                ], // Column children
              ), // Column
              ), // SingleChildScrollView
            ), // SafeArea
            
            // Theme Toggle Button
            Positioned(
              top: 12,
              right: 12,
              child: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black38 : Colors.white70,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.white30 : context.colors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      color: isDark ? Colors.white : context.colors.primary,
                      size: 22,
                    ),
                    onPressed: () {
                      ref.read(themeProvider.notifier).toggleTheme();
                    },
                  ),
                ),
              ),
            ),
          ], // Stack children
      ), // Stack
    ), // Scaffold
  ); // AnnotatedRegion
} // build()
} // _LoginScreenState

/// Botón secundario con borde, usado por los accesos que aún no tienen
/// backend. `filled` lo pinta sobre la superficie del tema (Google en el
/// mockup va sobre fondo claro); sin él queda transparente.
class _OutlinedAction extends StatelessWidget {
  final String label;
  final Widget leading;
  final VoidCallback? onTap;
  final bool filled;

  const _OutlinedAction({
    required this.label,
    required this.leading,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      enabled: onTap != null,
      child: Material(
        color: filled ? context.colors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: filled
                    ? context.firefly.cardBorder
                    : context.colors.primary.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                leading,
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
