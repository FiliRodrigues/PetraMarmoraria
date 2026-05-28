import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authProvider.notifier).login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) context.go('/');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 600 ? 420.0 : screenWidth * 0.92;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1621),
      body: Stack(
        children: [
          // Background orbs
          const _BackgroundOrbs(),

          Center(
            child: SingleChildScrollView(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: SizedBox(
                    width: cardWidth,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.10)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 44),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Logo
                                Center(
                                  child: Container(
                                    width: 72, height: 72,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF0A3D62), Color(0xFF1565A8)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0A3D62).withOpacity(0.4),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(LucideIcons.gem, color: Colors.white, size: 32),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'PETRA MARMORARIA',
                                  textAlign: TextAlign.center,
                                  style: AppTheme.syne(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ).copyWith(letterSpacing: 1.5),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Sistema de Gestão ERP',
                                  textAlign: TextAlign.center,
                                  style: AppTheme.jakarta(
                                    fontSize: 12.5,
                                    color: Colors.white.withOpacity(0.45),
                                  ),
                                ),
                                const SizedBox(height: 36),

                                // Email
                                _GlassField(
                                  controller: _emailController,
                                  label: 'E-mail',
                                  icon: LucideIcons.mail,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: Validators.validateEmail,
                                  onSubmitted: (_) => _handleLogin(),
                                ),
                                const SizedBox(height: 16),

                                // Senha
                                _GlassField(
                                  controller: _passwordController,
                                  label: 'Senha',
                                  icon: LucideIcons.lock,
                                  obscureText: _obscurePassword,
                                  validator: Validators.validatePassword,
                                  onSubmitted: (_) => _handleLogin(),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                                      size: 16,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),

                                // Esqueceu senha
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => context.push('/forgot-password'),
                                    child: Text(
                                      'Esqueceu a senha?',
                                      style: AppTheme.jakarta(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withOpacity(0.55),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // Erro
                                if (_errorMessage != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      _errorMessage!,
                                      style: AppTheme.jakarta(fontSize: 12.5, color: AppColors.error),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Botão entrar
                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 18, height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation(Colors.white),
                                            ),
                                          )
                                        : Text('ENTRAR',
                                            style: AppTheme.jakarta(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ).copyWith(letterSpacing: 1)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Glass text field ──────────────────────────────────────────────────────────
class _GlassField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;

  const _GlassField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.onSubmitted,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      style: AppTheme.jakarta(fontSize: 14, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTheme.jakarta(fontSize: 13, color: Colors.white.withValues(alpha: 0.55)),
        prefixIcon: Icon(icon, size: 16, color: Colors.white.withOpacity(0.45)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.07),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error.withOpacity(0.6)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        errorStyle: AppTheme.jakarta(fontSize: 11, color: AppColors.error),
      ),
    );
  }
}

// ── Background orbs decorativos ───────────────────────────────────────────────
class _BackgroundOrbs extends StatelessWidget {
  const _BackgroundOrbs();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -60, right: -60,
          child: _Orb(size: 220, color: const Color(0xFF0A3D62)),
        ),
        Positioned(
          bottom: -40, left: -40,
          child: _Orb(size: 180, color: const Color(0xFF1A5276)),
        ),
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.35), color.withOpacity(0)],
        ),
      ),
    );
  }
}
