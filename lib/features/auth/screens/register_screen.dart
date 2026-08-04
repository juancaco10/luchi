import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/firefly_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../../../widgets/custom_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier).register(
          _nameCtrl.text.trim(),
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );
    if (ok && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;
    final error = authState is AuthError ? authState.message : null;


    // Ver login_screen.dart: misma corrección de contraste mínima hasta
    // que la Fase 2 migre esta pantalla a respetar el tema real.
    return Theme(
      data: AppTheme.darkTheme,
      child: Scaffold(
      backgroundColor: AppTheme.darkTheme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(gradient: context.firefly.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                IconButton(
                  onPressed: () => context.go('/login'),
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      color: context.text.bodyMedium?.color),
                  style: IconButton.styleFrom(
                    backgroundColor: context.firefly.cardSurface,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ).animate().fadeIn(),

                const SizedBox(height: 24),

                Text(
                  'Únete como\nGuardián 🪲',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: context.colors.onSurface,
                    height: 1.2,
                  ),
                ).animate(delay: 100.ms).fadeIn().slideY(begin: -0.2, end: 0),

                const SizedBox(height: 8),

                Text(
                  'Crea tu cuenta gratuita y empieza a proteger las luciérnagas.',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    color: context.text.bodyMedium?.color,
                    height: 1.5,
                  ),
                ).animate(delay: 150.ms).fadeIn(),

                const SizedBox(height: 32),

                if (error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.colors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.colors.error.withValues(alpha: 0.4)),
                    ),
                    child: Row(children: [
                      Icon(Icons.error_outline_rounded,
                          color: context.colors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(error,
                            style: TextStyle(
                                color: context.colors.error,
                                fontFamily: 'Nunito',
                                fontSize: 14)),
                      ),
                    ]),
                  ).animate().fadeIn().shake(),
                  const SizedBox(height: 20),
                ],

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildField(
                        controller: _nameCtrl,
                        label: 'Tu nombre o apodo',
                        icon: Icons.person_outline_rounded,
                        delay: 200,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Campo requerido';
                          if (v.length < 2) return 'Mínimo 2 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        controller: _emailCtrl,
                        label: 'Correo electrónico',
                        icon: Icons.email_outlined,
                        delay: 250,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Campo requerido';
                          if (!v.contains('@')) return 'Correo inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        controller: _passwordCtrl,
                        label: 'Contraseña',
                        icon: Icons.lock_outline_rounded,
                        delay: 300,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
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
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Campo requerido';
                          if (v.length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        controller: _confirmCtrl,
                        label: 'Confirmar contraseña',
                        icon: Icons.lock_outline_rounded,
                        delay: 350,
                        obscureText: true,
                        validator: (v) {
                          if (v != _passwordCtrl.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      AppButton(
                        label: 'Crear mi cuenta',
                        onPressed: isLoading ? null : _register,
                        isLoading: isLoading,
                      ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿Ya tienes cuenta? ',
                            style: TextStyle(
                                color: context.text.bodyMedium?.color,
                                fontFamily: 'Nunito',
                                fontSize: 14),
                          ),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                            ),
                            child: Text(
                              'Inicia sesión',
                              style: TextStyle(
                                  color: context.colors.primary,
                                  fontFamily: 'Nunito',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ).animate(delay: 450.ms).fadeIn(),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required int delay,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: TextStyle(color: context.colors.onSurface, fontFamily: 'Nunito'),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: context.text.bodyMedium?.color, size: 20),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    ).animate(delay: Duration(milliseconds: delay)).fadeIn().slideX(begin: -0.1, end: 0);
  }
}
