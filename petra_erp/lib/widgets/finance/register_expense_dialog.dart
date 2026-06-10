import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/error_messages.dart';
import '../../core/utils/formatters.dart';
import '../../models/expense.dart';
import '../../providers/providers.dart';
import '../common/app_button.dart';

/// Dialog para criar ou editar uma despesa/registro financeiro.
///
/// Chamado via [RegisterExpenseDialog.show], que retorna `true` se salvou.
class RegisterExpenseDialog extends ConsumerStatefulWidget {
  /// Se informado, o dialog opera em modo edição.
  final Expense? existing;
  /// ID do fornecedor para pré-preencher na nova despesa.
  final String? supplierId;

  const RegisterExpenseDialog({super.key, this.existing, this.supplierId});

  /// Abre o dialog e retorna `true` se salvou com sucesso.
  static Future<bool> show(BuildContext context, {Expense? existing, String? supplierId}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => RegisterExpenseDialog(existing: existing, supplierId: supplierId),
    );
    return result ?? false;
  }

  @override
  ConsumerState<RegisterExpenseDialog> createState() =>
      _RegisterExpenseDialogState();
}

class _RegisterExpenseDialogState
    extends ConsumerState<RegisterExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  late String _category;
  late String _type;
  DateTime? _dueDate;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _descriptionController = TextEditingController(text: e?.description ?? '');
    _amountController = TextEditingController(
      text: e != null ? Formatters.formatCurrency(e.amount) : '',
    );
    _notesController = TextEditingController(text: e?.notes ?? '');
    _category = e?.category ?? 'material';
    _type = e?.type ?? 'despesa';
    _dueDate = e?.dueDate;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final raw = _amountController.text
        .replaceAll(RegExp(r'[R\$\s]'), '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    final amount = double.tryParse(raw) ?? 0;

    final expense = _isEdit
        ? widget.existing!.copyWith(
            description: _descriptionController.text.trim(),
            category: _category,
            type: _type,
            amount: amount,
            dueDate: _dueDate,
            supplierId: widget.supplierId ?? widget.existing!.supplierId,
            notes:
                _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          )
        : Expense(
            id: '',
            description: _descriptionController.text.trim(),
            category: _category,
            type: _type,
            amount: amount,
            status: 'pendente',
            dueDate: _dueDate,
            supplierId: widget.supplierId,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            createdAt: DateTime.now(),
          );

    try {
      if (_isEdit) {
        await ref.read(expenseProvider.notifier).update(expense);
      } else {
        await ref.read(expenseProvider.notifier).create(expense);
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
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
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
                      child: const Icon(LucideIcons.receipt,
                          size: 20, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isEdit ? 'Editar registro' : 'Novo registro',
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

                // Descrição
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    hintText: 'Ex: Compra de material',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe a descrição' : null,
                ),
                const SizedBox(height: 12),

                // Categoria
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: Expense.categoryLabels.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _category = v ?? 'material'),
                ),
                const SizedBox(height: 12),

                // Tipo (receita / despesa)
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(
                        value: 'despesa', child: Text('Despesa')),
                    DropdownMenuItem(
                        value: 'receita', child: Text('Receita')),
                  ],
                  onChanged: (v) =>
                      setState(() => _type = v ?? 'despesa'),
                ),
                const SizedBox(height: 12),

                // Valor
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Valor',
                    hintText: 'R\$ 0,00',
                  ),
                  validator: (v) {
                    final cleaned = (v ?? '')
                        .replaceAll(RegExp(r'[R\$\s]'), '')
                        .replaceAll('.', '')
                        .replaceAll(',', '.');
                    final parsed = double.tryParse(cleaned);
                    if (parsed == null || parsed <= 0) {
                      return 'Informe um valor maior que zero';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Data de vencimento
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _dueDate == null
                            ? 'Sem vencimento'
                            : 'Vencimento: ${AppDateUtils.formatDate(_dueDate)}',
                        style: AppTheme.jakarta(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                    AppButton(
                      label: _dueDate == null ? 'Definir data' : 'Alterar',
                      size: AppButtonSize.sm,
                      variant: AppButtonVariant.outline,
                      icon: LucideIcons.calendar,
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dueDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _dueDate = picked);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Notas
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
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
                      onPressed:
                          _saving ? null : () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 9),
                    AppButton(
                      label: _isEdit ? 'Salvar' : 'Registrar',
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
    );
  }
}
