import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/supabase_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String perfil;

  const LoginScreen({super.key, this.perfil = 'admin'});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _rememberBiometric = false;

  Color get _accentColor =>
      widget.perfil == 'vendedor' ? AppColors.accent : AppColors.primary;

  String get _titleLabel =>
      widget.perfil == 'vendedor' ? 'VENDEDOR' : 'ADMINISTRADOR';

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final service = ref.read(biometricAuthServiceProvider);
    final available = await service.isAvailable();
    final enabled = available && await service.isEnabled();
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
    });
  }

  @override
  void dispose() {
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

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    await ref.read(authProvider.notifier).login(email, password);

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.hasError) {
      final msg = authState.error.toString().replaceAll('Exception: ', '');
      setState(() {
        _errorMessage = msg.contains('Invalid login credentials')
            ? 'E-mail ou senha inválidos.'
            : msg;
        _isLoading = false;
      });
    } else {
      if (_rememberBiometric && _biometricAvailable) {
        try {
          final session = ref.read(supabaseClientProvider).auth.currentSession;
          if (session != null && session.refreshToken != null) {
            await ref.read(biometricAuthServiceProvider).saveSession(
              session.accessToken,
              session.refreshToken!,
            );
          }
      } catch (e) { debugPrint('Biometria save error: $e'); }
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleBiometricLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final session = await ref
          .read(biometricAuthServiceProvider)
          .authenticateAndGetSession();
      if (session == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      await ref.read(authProvider.notifier).loginWithSession(
        session.refreshToken,
      );
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.hasError) {
      final msg = authState.error.toString().replaceAll('Exception: ', '');
      setState(() {
        _errorMessage = msg.contains('Invalid login credentials')
            ? 'Credenciais biométricas inválidas.'
            : msg;
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;
    final cardWidth = isDesktop ? 400.0 : screenWidth * 0.9;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textSecondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/entrar'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: cardWidth,
              minHeight: isDesktop ? 500.0 : 0.0,
            ),
            child: Card(
              elevation: 4.0,
              color: AppColors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.store_mall_directory_outlined,
                        size: 64.0,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        'PETRA MARMORARIA',
                        textAlign: TextAlign.center,
                        style: AppTheme.syne(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: _accentColor,
                        ).copyWith(letterSpacing: 1.5),
                      ),
                      Text(
                        _titleLabel,
                        textAlign: TextAlign.center,
                        style: AppTheme.jakarta(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _accentColor,
                        ).copyWith(letterSpacing: 3),
                      ),
                      const SizedBox(height: 32.0),

                      // Email Input
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: Validators.validateEmail,
                        onFieldSubmitted: (_) => _handleLogin(),
                      ),
                      const SizedBox(height: 20.0),

                      // Password Input
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: Validators.validatePassword,
                        onFieldSubmitted: (_) => _handleLogin(),
                      ),

                      // Forgot Password Link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.push('/forgot-password'),
                          child: Text(
                            'Esqueceu a senha?',
                            style: AppTheme.jakarta(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8.0),

                      // Error message placeholder
                      if (_errorMessage != null) ...[
                        Text(
                          _errorMessage!,
                          style: AppTheme.jakarta(
                            fontSize: 13.0,
                            color: AppColors.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16.0),
                      ],

                      // Login Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          foregroundColor: AppColors.background,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20.0,
                                width: 20.0,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.background,
                                  ),
                                ),
                              )
                            : const Text('ENTRAR'),
                      ),

                      if (_biometricEnabled) ...[
                        const SizedBox(height: 12.0),
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleBiometricLogin,
                          icon: const Icon(Icons.fingerprint),
                          label: const Text('Entrar com biometria'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _accentColor,
                            side: BorderSide(color: _accentColor),
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                          ),
                        ),
                      ] else if (_biometricAvailable) ...[
                        const SizedBox(height: 4.0),
                        CheckboxListTile(
                          value: _rememberBiometric,
                          onChanged: (v) => setState(() => _rememberBiometric = v ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          activeColor: _accentColor,
                          title: Text(
                            'Ativar entrada por biometria neste aparelho',
                            style: AppTheme.jakarta(fontSize: 12.5, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
