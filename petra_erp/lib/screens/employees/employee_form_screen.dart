import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../models/profile.dart';
import '../../providers/employee_provider.dart';
import '../../providers/supabase_provider.dart';
import '../../widgets/widgets.dart';

/// Screen to create or edit an employee profile.
class EmployeeFormScreen extends ConsumerStatefulWidget {
  final String? id;

  const EmployeeFormScreen({
    super.key,
    this.id,
  });

  @override
  ConsumerState<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends ConsumerState<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedRole = 'vendedor';
  bool _isActive = true;
  bool _isEditing = false;
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _roles = [
    'admin',
    'vendedor',
    'cortador',
    'montador',
    'entregador',
  ];

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
          _selectedRole = _roles.contains(profile.role.toLowerCase()) 
              ? profile.role.toLowerCase() 
              : 'vendedor';
          _isActive = profile.active;
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
          role: _selectedRole,
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          active: _isActive,
          createdAt: DateTime.now(),
        );

        await ref.read(employeeProvider.notifier).updateEmployee(updatedProfile);
        if (mounted) {
          context.pop();
        }
      } else {
        final profileService = ref.read(profileServiceProvider);
        await profileService.createProfile(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
          role: _selectedRole,
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        );

        await ref.read(employeeProvider.notifier).loadEmployees();

        if (mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Funcionário ${_nameController.text.trim()} cadastrado com sucesso!'),
              backgroundColor: AppColors.staleOk,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao salvar funcionário: $e';
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
    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'Salvando funcionário...',
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Editar Funcionário' : 'Cadastrar Novo Funcionário'),
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
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: AppTheme.jakarta(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.error),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                    ],

                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome Completo *',
                        prefixIcon: Icon(LucideIcons.user, size: 16),
                      ),
                      validator: (val) => Validators.validateRequired(val, 'Nome'),
                    ),
                    const SizedBox(height: 16.0),

                    // Email (restricted from editing)
                    TextFormField(
                      controller: _emailController,
                      enabled: !_isEditing,
                      decoration: const InputDecoration(
                        labelText: 'E-mail *',
                        prefixIcon: Icon(LucideIcons.mail, size: 16),
                        helperText: 'O e-mail é utilizado para o login do funcionário.',
                      ),
                      validator: Validators.validateEmail,
                    ),
                    const SizedBox(height: 16.0),

                    // Password (visible only when creating)
                    if (!_isEditing) ...[
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Senha de Acesso *',
                          prefixIcon: Icon(LucideIcons.lock, size: 16),
                          helperText: 'A senha deve possuir pelo menos 6 caracteres.',
                        ),
                        validator: Validators.validatePassword,
                      ),
                      const SizedBox(height: 16.0),
                    ],

                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefone de Contato',
                        prefixIcon: Icon(LucideIcons.phone, size: 16),
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Role Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Cargo / Função *',
                        prefixIcon: Icon(LucideIcons.briefcase, size: 16),
                      ),
                      items: _roles.map((role) {
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(role.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedRole = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16.0),

                    // Active Toggle (Visible only when editing)
                    if (_isEditing) ...[
                      Row(
                        children: [
                          Text(
                            'Status de Ativação:',
                            style: AppTheme.jakarta(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          Switch(
                            value: _isActive,
                            activeColor: AppColors.accent,
                            onChanged: (val) {
                              setState(() {
                                _isActive = val;
                              });
                            },
                          ),
                          Text(_isActive ? 'ATIVO' : 'INATIVO'),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                    ],

                    const SizedBox(height: 24.0),

                    // Buttons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => context.pop(),
                          child: Text('Cancelar', style: AppTheme.jakarta(fontSize: 13, color: AppColors.textMuted)),
                        ),
                        const SizedBox(width: 16.0),
                        ElevatedButton(
                          onPressed: _saveEmployee,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                          ),
                          child: Text(_isEditing ? 'SALVAR ALTERAÇÕES' : 'CADASTRAR'),
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
