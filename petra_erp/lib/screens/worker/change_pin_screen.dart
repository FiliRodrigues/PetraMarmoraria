import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/supabase_provider.dart';
import '../../widgets/widgets.dart';

class ChangePinScreen extends ConsumerStatefulWidget {
  const ChangePinScreen({super.key});

  @override
  ConsumerState<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends ConsumerState<ChangePinScreen> {
  final _currentKey = GlobalKey<PinKeypadState>();
  final _newKey = GlobalKey<PinKeypadState>();
  final _confirmKey = GlobalKey<PinKeypadState>();

  int _step = 0;
  String? _currentPin;
  String? _newPin;
  bool _isLoading = false;
  String? _errorMessage;

  void _handleCurrentComplete(String pin) {
    setState(() {
      _currentPin = pin;
      _step = 1;
      _errorMessage = null;
    });
  }

  void _handleNewComplete(String pin) {
    setState(() {
      _newPin = pin;
      _step = 2;
      _errorMessage = null;
    });
  }

  Future<void> _handleConfirmComplete(String pin) async {
    if (pin != _newPin) {
      setState(() {
        _errorMessage = 'Os PINs não coincidem. Tente novamente.';
        _step = 1;
        _newPin = null;
      });
      _confirmKey.currentState?.shake();
      _newKey.currentState?.clear();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(workerAuthServiceProvider);
      await service.changePin(_currentPin!, _newPin!);

      if (mounted) {
        AppSnackbar.success(context, 'PIN alterado com sucesso!');
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Trocar PIN'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _isLoading
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(strokeWidth: 2),
                    SizedBox(height: 16),
                    Text('Alterando PIN...'),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_step == 0) ...[
                      Icon(LucideIcons.lock,
                          size: 40, color: AppColors.accent.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      PinKeypad(
                        key: _currentKey,
                        label: 'Digite seu PIN atual',
                        error: _errorMessage != null,
                        onCompleted: _handleCurrentComplete,
                      ),
                    ] else if (_step == 1) ...[
                      Icon(LucideIcons.key,
                          size: 40, color: AppColors.primary.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      PinKeypad(
                        key: _newKey,
                        label: 'Digite o novo PIN',
                        error: _errorMessage != null,
                        onCompleted: _handleNewComplete,
                      ),
                    ] else if (_step == 2) ...[
                      Icon(LucideIcons.checkCheck,
                          size: 40, color: AppColors.success.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      PinKeypad(
                        key: _confirmKey,
                        label: 'Confirme o novo PIN',
                        error: _errorMessage != null,
                        onCompleted: _handleConfirmComplete,
                      ),
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: AppTheme.jakarta(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
