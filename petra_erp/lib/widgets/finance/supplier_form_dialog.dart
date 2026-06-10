import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_messages.dart';
import '../../models/supplier.dart';
import '../../providers/providers.dart';
import '../common/app_button.dart';

/// Dialog para criar ou editar um fornecedor.
///
/// Chamado via [SupplierFormDialog.show], que retorna `true` se salvou.
class SupplierFormDialog extends ConsumerStatefulWidget {
  /// Se informado, o dialog opera em modo edição.
  final Supplier? existing;

  const SupplierFormDialog({super.key, this.existing});

  /// Abre o dialog e retorna `true` se salvou com sucesso.
  static Future<bool> show(BuildContext context, {Supplier? existing}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => SupplierFormDialog(existing: existing),
    );
    return result ?? false;
  }

  @override
  ConsumerState<SupplierFormDialog> createState() =>
      _SupplierFormDialogState();
}

class _SupplierFormDialogState extends ConsumerState<SupplierFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _cnpjController;
  late final TextEditingController _phoneController;
  late final TextEditingController _phone2Controller;
  late final TextEditingController _emailController;
  late final TextEditingController _contactPersonController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late String _state;
  late final TextEditingController _notesController;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _cnpjController = TextEditingController(text: e?.cnpj ?? '');
    _phoneController = TextEditingController(text: e?.phone ?? '');
    _phone2Controller = TextEditingController(text: e?.phone2 ?? '');
    _emailController = TextEditingController(text: e?.email ?? '');
    _contactPersonController =
        TextEditingController(text: e?.contactPerson ?? '');
    _addressController = TextEditingController(text: e?.address ?? '');
    _cityController = TextEditingController(text: e?.city ?? '');
    _state = e?.state ?? 'SP';
    _notesController = TextEditingController(text: e?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cnpjController.dispose();
    _phoneController.dispose();
    _phone2Controller.dispose();
    _emailController.dispose();
    _contactPersonController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final supplier = _isEdit
        ? widget.existing!.copyWith(
            name: _nameController.text.trim(),
            cnpj: _cnpjController.text.trim().isEmpty
                ? null
                : _cnpjController.text.trim(),
            phone: _phoneController.text.trim(),
            phone2: _phone2Controller.text.trim().isEmpty
                ? null
                : _phone2Controller.text.trim(),
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            contactPerson: _contactPersonController.text.trim().isEmpty
                ? null
                : _contactPersonController.text.trim(),
            address: _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
            city: _cityController.text.trim().isEmpty
                ? null
                : _cityController.text.trim(),
            state: _state,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            updatedAt: DateTime.now(),
          )
        : Supplier(
            id: '',
            name: _nameController.text.trim(),
            cnpj: _cnpjController.text.trim().isEmpty
                ? null
                : _cnpjController.text.trim(),
            phone: _phoneController.text.trim(),
            phone2: _phone2Controller.text.trim().isEmpty
                ? null
                : _phone2Controller.text.trim(),
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            contactPerson: _contactPersonController.text.trim().isEmpty
                ? null
                : _contactPersonController.text.trim(),
            address: _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
            city: _cityController.text.trim().isEmpty
                ? null
                : _cityController.text.trim(),
            state: _state,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            createdAt: DateTime.now(),
          );

    try {
      if (_isEdit) {
        await ref.read(supplierProvider.notifier).update(supplier);
      } else {
        await ref.read(supplierProvider.notifier).create(supplier);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Título
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        child: const Icon(LucideIcons.truck,
                            size: 20, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isEdit ? 'Editar fornecedor' : 'Novo fornecedor',
                        style: AppTheme.syne(
                            fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Erro
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Text(_error!,
                          style: AppTheme.jakarta(
                              fontSize: 12, color: AppColors.error)),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Nome *
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome *',
                      hintText: 'Ex: Marmoraria Exemplo Ltda',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                  ),
                  const SizedBox(height: 12),

                  // CNPJ
                  TextFormField(
                    controller: _cnpjController,
                    decoration: const InputDecoration(
                      labelText: 'CNPJ',
                      hintText: '00.000.000/0000-00',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Telefone *
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Telefone *',
                      hintText: '(11) 99999-9999',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe o telefone'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Telefone 2
                  TextFormField(
                    controller: _phone2Controller,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Telefone 2',
                      hintText: '(11) 99999-9999',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'contato@exemplo.com',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Pessoa de Contato
                  TextFormField(
                    controller: _contactPersonController,
                    decoration: const InputDecoration(
                      labelText: 'Pessoa de Contato',
                      hintText: 'Nome da pessoa',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Endereço
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Endereço',
                      hintText: 'Rua, número, bairro',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cidade e Estado
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: 'Cidade',
                            hintText: 'São Paulo',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          initialValue: _state,
                          decoration: const InputDecoration(labelText: 'UF'),
                          items: Supplier.states
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _state = v ?? 'SP'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Observações
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Observações',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Botões
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AppButton(
                        label: 'Cancelar',
                        variant: AppButtonVariant.outline,
                        size: AppButtonSize.sm,
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 9),
                      AppButton(
                        label: _isEdit ? 'Salvar' : 'Cadastrar',
                        size: AppButtonSize.sm,
                        loading: _saving,
                        onPressed: _saving ? null : _save,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
