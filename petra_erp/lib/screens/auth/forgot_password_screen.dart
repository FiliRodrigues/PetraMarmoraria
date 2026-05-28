import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      await ref.read(authProvider.notifier).resetPassword(_emailController.text.trim());
      setState(() { _emailSent = true; });
    } catch (e) {
      setState(() { _errorMessage = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar Senha'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icon
                    Center(
                      child: Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(LucideIcons.keyRound, size: 24, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text('RECUPERAR SENHA',
                      textAlign: TextAlign.center,
                      style: AppTheme.syne(fontSize: 16, fontWeight: FontWeight.w800)
                        .copyWith(letterSpacing: 0.8)),
                    const SizedBox(height: 10),

                    Text(
                      _emailSent
                        ? 'As instruções de recuperação foram enviadas para o e-mail informado.'
                        : 'Insira seu e-mail cadastrado para receber o link de redefinição de senha.',
                      textAlign: TextAlign.center,
                      style: AppTheme.jakarta(fontSize: 13, color: AppColors.textMuted)),
                    const SizedBox(height: 28),

                    if (!_emailSent) ...[
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(LucideIcons.mail, size: 16),
                        ),
                        validator: Validators.validateEmail,
                        onFieldSubmitted: (_) => _handleResetPassword(),
                      ),
                      const SizedBox(height: 20),

                      if (_errorMessage != null) ...[
                        Text(_errorMessage!,
                          style: AppTheme.jakarta(fontSize: 13, color: AppColors.error),
                          textAlign: TextAlign.center),
                        const SizedBox(height: 14),
                      ],

                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleResetPassword,
                        child: _isLoading
                          ? const SizedBox(height: 18, width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('ENVIAR INSTRUÇÕES',
                              style: AppTheme.jakarta(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ] else ...[
                      ElevatedButton(
                        onPressed: () => context.pop(),
                        child: Text('VOLTAR PARA LOGIN',
                          style: AppTheme.jakarta(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
