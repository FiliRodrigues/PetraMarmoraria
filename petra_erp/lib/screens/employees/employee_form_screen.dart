import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../models/profile.dart';
import '../../providers/employee_provider.dart';
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
        // Edit existing profile
        final updatedProfile = Profile(
          id: widget.id!,
          email: _emailController.text.trim(),
          name: _nameController.text.trim(),
          role: _selectedRole,
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          active: _isActive,
          createdAt: DateTime.now(), // Ignored in update
        );

        await ref.read(employeeProvider.notifier).updateEmployee(updatedProfile);
        if (mounted) {
          context.pop();
        }
      } else {
        // Create new auth account. Warn first!
        final supabase = Supabase.instance.client;
        
        // Call signup with user metadata to trigger profile creation
        await supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          data: {
            'name': _nameController.text.trim(),
            'role': _selectedRole,
            'phone': _phoneController.text.trim(),
          },
        );

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Funcionário Cadastrado'),
              content: const Text(
                'O funcionário foi cadastrado com sucesso! Como as contas são vinculadas ao e-mail, '
                'você precisará logar novamente para retornar à sua conta de Administrador.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // pop dialog
                    context.go('/login'); // direct to login
                  },
                  child: const Text('OK'),
                ),
              ],
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
                          style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                    ],

                    if (!_isEditing) ...[
                      const AlertBanner(
                        message: 'Atenção: Ao criar um novo funcionário, você será desconectado temporariamente '
                            'devido ao fluxo de registro do Supabase.',
                        type: 'warning',
                      ),
                      const SizedBox(height: 16.0),
                    ],

                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome Completo *',
                        prefixIcon: Icon(Icons.person),
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
                        prefixIcon: Icon(Icons.email),
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
                          prefixIcon: Icon(Icons.lock),
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
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Role Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Cargo / Função *',
                        prefixIcon: Icon(Icons.work),
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
                          const Text(
                            'Status de Ativação:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Switch(
                            value: _isActive,
                            activeColor: AppColors.secondary,
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
                          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
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

/// Helper banner for warning user
class AlertBanner extends StatelessWidget {
  final String message;
  final String type;

  const AlertBanner({
    super.key,
    required this.message,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: type == 'warning' ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: type == 'warning' ? Colors.orange : Colors.blue),
      ),
      child: Row(
        children: [
          Icon(
            type == 'warning' ? Icons.warning_amber : Icons.info_outline,
            color: type == 'warning' ? Colors.orange : Colors.blue,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: type == 'warning' ? Colors.orange[900] : Colors.blue[900],
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
