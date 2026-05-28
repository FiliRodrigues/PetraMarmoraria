import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/supplier.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

class SupplierFormScreen extends ConsumerStatefulWidget {
  final String? id;

  const SupplierFormScreen({
    super.key,
    this.id,
  });

  @override
  ConsumerState<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends ConsumerState<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _cpfCnpjController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phone2Controller = TextEditingController();
  final _emailController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController(text: 'SP');
  final _notesController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.id != null;
    if (_isEditing) {
      _loadSupplierData();
    }
  }

  void _loadSupplierData() async {
    final suppliersState = ref.read(supplierProvider);
    suppliersState.maybeWhen(
      data: (list) {
        final idx = list.indexWhere((s) => s.id == widget.id);
        if (idx != -1) {
          _populateSupplierForm(list[idx]);
          return;
        }
      },
      orElse: () {},
    );
    try {
      final service = ref.read(supplierServiceProvider);
      final supplier = await service.getSupplierById(widget.id!);
      _populateSupplierForm(supplier);
    } catch (e) {
      setState(() { _errorMessage = 'Erro ao carregar fornecedor: $e'; });
    }
  }

  void _populateSupplierForm(Supplier supplier) {
    _nameController.text = supplier.name;
    _phoneController.text = Formatters.formatPhone(supplier.phone);
    _phone2Controller.text = supplier.phone2 != null ? Formatters.formatPhone(supplier.phone2!) : '';
    _cpfCnpjController.text = supplier.cpfCnpj ?? '';
    _emailController.text = supplier.email ?? '';
    _contactPersonController.text = supplier.contactPerson ?? '';
    _addressController.text = supplier.address ?? '';
    _cityController.text = supplier.city ?? '';
    _stateController.text = supplier.state;
    _notesController.text = supplier.notes ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cpfCnpjController.dispose();
    _phoneController.dispose();
    _phone2Controller.dispose();
    _emailController.dispose();
    _contactPersonController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveSupplier() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final cleanPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final cleanPhone2 = _phone2Controller.text.replaceAll(RegExp(r'\D'), '');

    final now = DateTime.now();

    final supplier = Supplier(
      id: _isEditing ? widget.id! : const Uuid().v4(),
      name: _nameController.text.trim(),
      cpfCnpj: _cpfCnpjController.text.trim().isEmpty ? null : _cpfCnpjController.text.trim(),
      phone: cleanPhone,
      phone2: cleanPhone2.isEmpty ? null : cleanPhone2,
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      contactPerson: _contactPersonController.text.trim().isEmpty ? null : _contactPersonController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      state: _stateController.text.trim().isEmpty ? 'SP' : _stateController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      active: true,
      createdAt: _isEditing ? DateTime.now() : now,
      updatedAt: now,
    );

    try {
      if (_isEditing) {
        await ref.read(supplierProvider.notifier).updateSupplier(supplier);
      } else {
        await ref.read(supplierProvider.notifier).addSupplier(supplier);
      }
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao salvar fornecedor: $e';
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
      message: 'Salvando informações...',
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Editar Fornecedor' : 'Cadastrar Novo Fornecedor'),
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
                        labelText: 'Nome / Razão Social *',
                        prefixIcon: Icon(LucideIcons.building2, size: 16),
                      ),
                      validator: (val) => Validators.validateRequired(val, 'Nome'),
                    ),
                    const SizedBox(height: 16.0),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [PhoneInputFormatter()],
                            decoration: const InputDecoration(
                              labelText: 'Telefone Principal *',
                              prefixIcon: Icon(LucideIcons.phone, size: 16),
                              hintText: '(00) 00000-0000',
                            ),
                            validator: (val) => Validators.validateRequired(val, 'Telefone principal'),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: TextFormField(
                            controller: _phone2Controller,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [PhoneInputFormatter()],
                            decoration: const InputDecoration(
                              labelText: 'Telefone Secundário',
                              prefixIcon: Icon(LucideIcons.smartphone, size: 16),
                              hintText: '(00) 00000-0000',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cpfCnpjController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [CpfCnpjInputFormatter()],
                            decoration: const InputDecoration(
                              labelText: 'CPF / CNPJ',
                              prefixIcon: Icon(LucideIcons.creditCard, size: 16),
                              hintText: '00.000.000/0000-00',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'E-mail',
                              prefixIcon: Icon(LucideIcons.mail, size: 16),
                            ),
                            validator: (val) {
                              if (val != null && val.isNotEmpty) {
                                return Validators.validateEmail(val);
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),

                    TextFormField(
                      controller: _contactPersonController,
                      decoration: const InputDecoration(
                        labelText: 'Pessoa de Contato',
                        prefixIcon: Icon(LucideIcons.user, size: 16),
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Endereço (Rua, Número, Bairro)',
                        prefixIcon: Icon(LucideIcons.mapPin, size: 16),
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(
                              labelText: 'Cidade',
                              prefixIcon: Icon(LucideIcons.building2, size: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _stateController,
                            maxLength: 2,
                            decoration: const InputDecoration(
                              labelText: 'UF',
                              counterText: '',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),

                    TextFormField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Observações Internas',
                        prefixIcon: Icon(LucideIcons.fileText, size: 16),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 32.0),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => context.pop(),
                          child: Text('Cancelar', style: AppTheme.jakarta(fontSize: 13, color: AppColors.textMuted)),
                        ),
                        const SizedBox(width: 16.0),
                        ElevatedButton(
                          onPressed: _saveSupplier,
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
