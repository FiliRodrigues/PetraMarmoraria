import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/roles.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_messages.dart';
import '../../core/utils/validators.dart';
import '../../models/profile.dart';
import '../../providers/employee_provider.dart';
import '../../widgets/widgets.dart';

class EmployeeFormScreen extends ConsumerStatefulWidget {
  final String? id;

  const EmployeeFormScreen({super.key, this.id});

  @override
  ConsumerState<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends ConsumerState<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  List<String> _selectedRoles = [];
  bool _isActive = true;
  bool _isEditing = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPinAccess = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.id != null;
    if (_isEditing) {
      _loadEmployeeData();
    }
  }

  void _loadEmployeeData() {
    final employeeState = ref.read(employeeProvider);
    employeeState.maybeWhen(
      data: (list) {
        try {
          final profile = list.firstWhere((e) => e.id == widget.id);
          _nameController.text = profile.name;
          _emailController.text = profile.email;
          _phoneController.text = profile.phone ?? '';
          _selectedRoles = [
            ...profile.roles,
          ].where((r) => AppRoles.all.contains(r)).toList();
          _isActive = profile.active;
          _isPinAccess = profile.loginMode == 'pin';
        } catch (_) {
          _errorMessage = 'Funcionário não encontrado no cache.';
        }
      },
      orElse: () {
        _errorMessage = 'Erro: Lista de funcionários não carregada.';
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoles.isEmpty) {
      setState(() => _errorMessage = 'Selecione pelo menos uma função.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isEditing) {
        final updatedProfile = Profile(
          id: widget.id!,
          email: _emailController.text.trim(),
          name: _nameController.text.trim(),
          roles: _selectedRoles,
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          active: _isActive,
          createdAt: DateTime.now(),
          loginMode: _isPinAccess ? 'pin' : 'email',
        );

        await ref
            .read(employeeProvider.notifier)
            .updateEmployee(updatedProfile);
        if (mounted) {
          context.pop();
        }
      } else {
        final phone = _phoneController.text.trim();

        if (_isPinAccess) {
          final uuidPart = DateTime.now().millisecondsSinceEpoch.toRadixString(
            36,
          );
          await ref
              .read(employeeProvider.notifier)
              .createEmployee(
                email: 'w-$uuidPart@petra.local',
                password: _generatePassword(),
                name: _nameController.text.trim(),
                roles: _selectedRoles,
                phone: phone.isEmpty ? null : phone,
                loginMode: 'pin',
              );
        } else {
          await ref
              .read(employeeProvider.notifier)
              .createEmployee(
                email: _emailController.text.trim(),
                password: _passwordController.text.trim(),
                name: _nameController.text.trim(),
                roles: _selectedRoles,
                phone: phone.isEmpty ? null : phone,
                loginMode: 'email',
              );
        }

        if (mounted) {
          AppSnackbar.success(context, 'Funcionário cadastrado com sucesso!');
          context.pop();
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = friendlyError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _unblock() async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Desbloquear funcionário',
      content: 'Isso permitirá que o funcionário tente acessar novamente.',
    );
    if (confirm && widget.id != null) {
      try {
        await ref.read(employeeProvider.notifier).unblockWorker(widget.id!);
        if (mounted) AppSnackbar.success(context, 'Funcionário desbloqueado.');
      } catch (e) {
        if (mounted) AppSnackbar.error(context, friendlyError(e));
      }
    }
  }

  Future<void> _resetPin() async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Redefinir PIN',
      content: 'O funcionário precisará criar um novo PIN no próximo acesso.',
    );
    if (confirm && widget.id != null) {
      try {
        await ref.read(employeeProvider.notifier).resetWorkerPin(widget.id!);
        if (mounted) AppSnackbar.success(context, 'PIN redefinido.');
      } catch (e) {
        if (mounted) AppSnackbar.error(context, friendlyError(e));
      }
    }
  }

  Future<void> _resetPassword() async {
    final formKey = GlobalKey<FormState>();
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Redefinir senha'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nova senha *',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmar senha *',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (val) => val != passCtrl.text
                    ? 'As senhas não coincidem'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Redefinir'),
          ),
        ],
      ),
    );

    if (ok == true && widget.id != null) {
      try {
        await ref
            .read(employeeProvider.notifier)
            .resetEmployeePassword(widget.id!, passCtrl.text.trim());
        if (mounted) AppSnackbar.success(context, 'Senha redefinida.');
      } catch (e) {
        if (mounted) AppSnackbar.error(context, friendlyError(e));
      }
    }

    passCtrl.dispose();
    confirmCtrl.dispose();
  }

  Future<void> _toggleActive() async {
    final confirm = await ConfirmDialog.show(
      context,
      title: _isActive ? 'Desativar funcionário' : 'Ativar funcionário',
      content: _isActive
          ? 'O funcionário não poderá mais acessar o sistema.'
          : 'O funcionário poderá acessar o sistema novamente.',
    );
    if (confirm && widget.id != null) {
      try {
        await ref
            .read(employeeProvider.notifier)
            .toggleActiveStatus(widget.id!, !_isActive);
        if (mounted) {
          setState(() => _isActive = !_isActive);
          AppSnackbar.success(
            context,
            _isActive ? 'Funcionário ativado.' : 'Funcionário desativado.',
          );
        }
      } catch (e) {
        if (mounted) AppSnackbar.error(context, friendlyError(e));
      }
    }
  }

  String _generatePassword() {
    final rng = List.generate(16, (i) {
      const chars =
          'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^';
      final ms = DateTime.now().microsecondsSinceEpoch;
      return chars[(ms + i) % chars.length];
    });
    return rng.join();
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'Salvando funcionário...',
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEditing ? 'Editar Funcionário' : 'Cadastrar Novo Funcionário',
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: AppTheme.jakarta(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                    ],

                    if (_isEditing && _isPinAccess) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.vpn_key,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Acesso por PIN',
                            style: AppTheme.jakarta(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const Spacer(),
                          AppButton(
                            label: 'Desbloquear',
                            icon: LucideIcons.unlock,
                            variant: AppButtonVariant.soft,
                            size: AppButtonSize.sm,
                            onPressed: _unblock,
                          ),
                          const SizedBox(width: 8),
                          AppButton(
                            label: 'Redefinir PIN',
                            icon: LucideIcons.rotateCw,
                            variant: AppButtonVariant.outline,
                            size: AppButtonSize.sm,
                            onPressed: _resetPin,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                    ],

                    if (_isEditing && !_isPinAccess) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.email_outlined,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Acesso por e-mail',
                            style: AppTheme.jakarta(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const Spacer(),
                          AppButton(
                            label: 'Redefinir senha',
                            icon: LucideIcons.keyRound,
                            variant: AppButtonVariant.outline,
                            size: AppButtonSize.sm,
                            onPressed: _resetPassword,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                    ],

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome Completo *',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (val) =>
                          Validators.validateRequired(val, 'Nome'),
                    ),
                    const SizedBox(height: 16.0),

                    if (!_isEditing) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _AccessChip(
                              icon: Icons.email_outlined,
                              label: 'Email + Senha',
                              selected: !_isPinAccess,
                              onTap: () => setState(() => _isPinAccess = false),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _AccessChip(
                              icon: LucideIcons.fingerprint,
                              label: 'PIN (Produção)',
                              selected: _isPinAccess,
                              onTap: () => setState(() => _isPinAccess = true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                    ],

                    if (!_isPinAccess) ...[
                      TextFormField(
                        controller: _emailController,
                        enabled: !_isEditing,
                        decoration: const InputDecoration(
                          labelText: 'E-mail *',
                          prefixIcon: Icon(Icons.email),
                          helperText:
                              'O e-mail é utilizado para o login do funcionário.',
                        ),
                        validator: Validators.validateEmail,
                      ),
                      const SizedBox(height: 16.0),
                    ],

                    if (!_isPinAccess && !_isEditing) ...[
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Senha de Acesso *',
                          prefixIcon: Icon(Icons.lock),
                          helperText:
                              'A senha deve possuir pelo menos 6 caracteres.',
                        ),
                        validator: Validators.validatePassword,
                      ),
                      const SizedBox(height: 16.0),
                    ],

                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefone de Contato',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: Validators.validatePhoneOptional,
                    ),
                    const SizedBox(height: 16.0),

                    Text(
                      'Funções *',
                      style: AppTheme.jakarta(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppRoles.all.map((role) {
                        final selected = _selectedRoles.contains(role);
                        final color = AppRoles.roleColor(role);
                        return FilterChip(
                          label: Text(AppRoles.roleLabel(role)),
                          selected: selected,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedRoles = [..._selectedRoles, role];
                              } else {
                                _selectedRoles = _selectedRoles
                                    .where((r) => r != role)
                                    .toList();
                              }
                            });
                          },
                          selectedColor: color.withValues(alpha: 0.15),
                          checkmarkColor: color,
                          labelStyle: AppTheme.jakarta(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: selected ? color : AppColors.textSecondary,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16.0),

                    if (_isEditing) ...[
                      Row(
                        children: [
                          Text(
                            'Status:',
                            style: AppTheme.jakarta(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Switch(
                            value: _isActive,
                            activeThumbColor: AppColors.secondary,
                            onChanged: (val) {
                              setState(() => _isActive = val);
                            },
                          ),
                          Text(_isActive ? 'ATIVO' : 'INATIVO'),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isActive ? _toggleActive : null,
                              icon: Icon(
                                LucideIcons.userX,
                                size: 16,
                                color: AppColors.error,
                              ),
                              label: const Text('Desativar'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    const SizedBox(height: 20.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => context.pop(),
                          child: Text(
                            'Cancelar',
                            style: AppTheme.jakarta(
                              color: AppColors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _saveEmployee,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32.0,
                              vertical: 16.0,
                            ),
                          ),
                          child: Text(
                            _isEditing ? 'SALVAR ALTERAÇÕES' : 'CADASTRAR',
                          ),
                        ),
                      ],
                    ),
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

class _AccessChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AccessChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTheme.jakarta(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
