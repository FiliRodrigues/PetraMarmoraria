import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../models/profile.dart';
import '../../providers/employee_provider.dart';
import '../../widgets/widgets.dart';

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
  final _phoneController = TextEditingController();

  final Set<String> _selectedRoles = {};
  bool _isActive = true;
  bool _isEditing = false;
  bool _isLoading = false;
  String? _errorMessage;

  static const _availableRoles = [
    'admin',
    'vendedor',
    'cortador',
    'montador',
    'entregador',
  ];

  static const _roleLabels = {
    'admin': 'Administrador',
    'vendedor': 'Vendedor',
    'cortador': 'Cortador',
    'montador': 'Montador',
    'entregador': 'Entregador',
  };

  static const _roleIcons = {
    'admin': LucideIcons.shield,
    'vendedor': LucideIcons.badgeDollarSign,
    'cortador': LucideIcons.scissors,
    'montador': LucideIcons.wrench,
    'entregador': LucideIcons.truck,
  };

  static const _roleColors = <String, Color>{
    'admin': AppColors.staleCrit,
    'vendedor': AppColors.primary,
    'cortador': AppColors.corte,
    'montador': AppColors.montagem,
    'entregador': AppColors.entrega,
  };

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
          _phoneController.text = profile.phone ?? '';
          _selectedRoles.addAll(profile.roles);
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
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRoles.isEmpty) {
      setState(() {
        _errorMessage = 'Selecione pelo menos uma função.';
      });
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
          name: _nameController.text.trim(),
          roles: _selectedRoles.toList(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          active: _isActive,
          createdAt: DateTime.now(),
        );
        await ref.read(employeeProvider.notifier).updateEmployee(updatedProfile);
        if (mounted) context.pop();
      } else {
        await ref.read(employeeProvider.notifier).createEmployee(
          name: _nameController.text.trim(),
          roles: _selectedRoles.toList(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        );
        if (mounted) context.pop();
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

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome Completo *',
                        prefixIcon: Icon(LucideIcons.user, size: 16),
                      ),
                      validator: (val) => Validators.validateRequired(val, 'Nome'),
                    ),
                    const SizedBox(height: 16.0),

                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefone de Contato',
                        prefixIcon: Icon(LucideIcons.phone, size: 16),
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    Text('Funções *',
                      style: AppTheme.syne(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8.0),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableRoles.map((role) {
                        final selected = _selectedRoles.contains(role);
                        final color = _roleColors[role] ?? AppColors.primary;
                        return FilterChip(
                          selected: selected,
                          label: Text(_roleLabels[role] ?? role,
                            style: AppTheme.jakarta(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                          selectedColor: color,
                          checkmarkColor: Colors.white,
                          backgroundColor: color.withValues(alpha: 0.1),
                          side: BorderSide(color: selected ? color : AppColors.border),
                          avatar: Icon(_roleIcons[role] ?? LucideIcons.user,
                            size: 16,
                            color: selected ? Colors.white : color,
                          ),
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedRoles.add(role);
                              } else {
                                _selectedRoles.remove(role);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    if (_isEditing) ...[
                      const SizedBox(height: 20.0),
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
                    ],

                    const SizedBox(height: 24.0),

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
