import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/roles.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/supabase_provider.dart';
import '../../services/worker_auth_service.dart';
import '../../widgets/widgets.dart';

class WorkerPinScreen extends ConsumerStatefulWidget {
  const WorkerPinScreen({super.key});

  @override
  ConsumerState<WorkerPinScreen> createState() => _WorkerPinScreenState();
}

class _WorkerPinScreenState extends ConsumerState<WorkerPinScreen> {
  PinWorker? _worker;
  final _keypadKey = GlobalKey<PinKeypadState>();

  String? _firstPin;
  String _mode = 'verify';
  bool _isLoading = false;
  String? _errorMessage;
  int? _remainingAttempts;
  bool _blocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWorker());
  }

  void _loadWorker() {
    final route = GoRouterState.of(context);
    final extra = route.extra;
    if (extra is PinWorker) {
      setState(() {
        _worker = extra;
        if (!extra.pinSet) {
          _mode = 'create';
        }
      });
    } else {
      if (mounted) context.go('/entrar');
    }
  }

  Future<void> _handlePinComplete(String pin) async {
    if (_worker == null || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(workerAuthServiceProvider);

      if (_mode == 'create') {
        _firstPin = pin;
        setState(() {
          _mode = 'confirm';
          _isLoading = false;
        });
        _keypadKey.currentState?.clear();
        return;
      }

      if (_mode == 'confirm') {
        if (pin != _firstPin) {
          setState(() {
            _errorMessage = 'Os PINs não coincidem. Tente novamente.';
            _mode = 'create';
            _firstPin = null;
            _isLoading = false;
          });
          _keypadKey.currentState?.shake();
          return;
        }

        await service.setPin(_worker!.id, _firstPin!);
        if (mounted) context.go('/meu-painel');
        return;
      }

      final result = await service.verifyPin(_worker!.id, pin);

      if (result.code == 'blocked') {
        if (mounted) {
          setState(() {
            _blocked = true;
            _isLoading = false;
          });
        }
        return;
      }

      if (result.code == 'not_set') {
        if (mounted) {
          setState(() {
            _mode = 'create';
            _isLoading = false;
          });
        }
        _keypadKey.currentState?.clear();
        return;
      }

      if (result.code == 'wrong_pin') {
        if (mounted) {
          final remaining = result.remaining;
          setState(() {
            _remainingAttempts = remaining;
            _errorMessage = remaining != null && remaining > 0
                ? 'PIN incorreto. Tentativas restantes: $_remainingAttempts'
                : 'PIN incorreto.';
            _isLoading = false;
          });
        }
        _keypadKey.currentState?.shake();
        return;
      }

      // Sucesso: a sessão foi definida no service. Navega explicitamente em vez
      // de depender só do redirect reagir ao onAuthStateChange.
      if (mounted) context.go('/meu-painel');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
      _keypadKey.currentState?.shake();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_worker == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final w = _worker!;
    final primaryRole = w.roles.isNotEmpty ? w.roles.first : '';
    final color = AppRoles.roleColor(primaryRole);

    if (_blocked) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                ),
                child: const Icon(LucideIcons.lock, size: 36, color: AppColors.error),
              ),
              const SizedBox(height: 20),
              Text(
                'Acesso Bloqueado',
                style: AppTheme.syne(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Muitas tentativas incorretas.\nProcure o administrador para desbloquear.',
                textAlign: TextAlign.center,
                style: AppTheme.jakarta(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () => context.go('/entrar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Voltar ao início'),
              ),
            ],
          ),
        ),
      );
    }

    String label;
    if (_mode == 'create') {
      label = 'Crie seu PIN de 4 dígitos';
    } else if (_mode == 'confirm') {
      label = 'Confirme seu PIN';
    } else {
      label = 'Digite seu PIN de 4 dígitos';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(''),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/funcionario'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.20),
                      AppColors.accent.withValues(alpha: 0.14),
                    ],
                  ),
                ),
                child: Text(
                  AppRoles.initials(w.name),
                  style: AppTheme.syne(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                w.name,
                style: AppTheme.syne(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: w.roles.map((role) {
                  final rc = AppRoles.roleColor(role);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: rc.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Text(
                      AppRoles.roleLabel(role).toUpperCase(),
                      style: AppTheme.jakarta(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: rc,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              PinKeypad(
                key: _keypadKey,
                label: label,
                error: _errorMessage != null,
                onCompleted: _handlePinComplete,
              ),
              if (_isLoading) ...[
                const SizedBox(height: 20),
                const CircularProgressIndicator(strokeWidth: 2),
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
            ],
          ),
        ),
      ),
    );
  }
}
