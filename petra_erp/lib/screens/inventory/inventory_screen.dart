import 'package:flutter/material.dart';
import '../../core/utils/error_messages.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/stock_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

/// Tela de Estoque de materiais: quantidade atual, alerta de estoque baixo,
/// registro de movimentações e histórico por material.
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => setState(() => _searchText = _searchController.text),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productProvider);
    final lowStock = ref.watch(lowStockProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estoque'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => ref.read(productProvider.notifier).loadProducts(),
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(friendlyError(err))),
        data: (products) {
          final query = _searchText.trim().toLowerCase();
          final visible = query.isEmpty
              ? products
              : products
                    .where((p) => p.name.toLowerCase().contains(query))
                    .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: TextField(
                          controller: _searchController,
                          style: AppTheme.jakarta(fontSize: 13),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Buscar material...',
                            filled: true,
                            fillColor: AppColors.surface,
                            prefixIcon: const Icon(
                              Icons.search,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusSm,
                              ),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Banner de estoque baixo
              if (lowStock.isNotEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.staleCrit.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: AppColors.staleCrit.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.alertTriangle,
                        size: 16,
                        color: AppColors.staleCrit,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${lowStock.length} material(is) com estoque baixo',
                          style: AppTheme.jakarta(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.staleCrit,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: visible.isEmpty
                    ? const EmptyState(
                        title: 'Nenhum material',
                        message:
                            'Cadastre materiais na tela de Produtos para controlar o estoque.',
                        icon: LucideIcons.package,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        itemCount: visible.length,
                        itemBuilder: (context, i) =>
                            _InventoryTile(product: visible[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InventoryTile extends ConsumerWidget {
  final Product product;
  const _InventoryTile({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final low = product.isLowStock;
    final color = low ? AppColors.staleCrit : AppColors.staleOk;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: low
              ? AppColors.staleCrit.withValues(alpha: 0.5)
              : AppColors.border,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(
              low ? LucideIcons.alertTriangle : LucideIcons.package,
              size: 18,
              color: color,
            ),
          ),
          title: Text(
            product.name,
            style: AppTheme.jakarta(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Mínimo: ${_fmt(product.minStock)} ${product.unit}',
              style: AppTheme.jakarta(
                fontSize: 11.5,
                color: AppColors.textMuted,
              ),
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_fmt(product.stockQuantity)} ${product.unit}',
                style: AppTheme.numeric(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              if (low)
                Text(
                  'Estoque baixo',
                  style: AppTheme.jakarta(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.staleCrit,
                  ),
                ),
            ],
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: () => _showMovementDialog(context, ref),
                icon: const Icon(LucideIcons.arrowDownUp, size: 16),
                label: const Text('Registrar movimentação'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _MovementHistory(productId: product.id),
          ],
        ),
      ),
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  Future<void> _showMovementDialog(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _MovementDialog(product: product),
    );
  }
}

class _MovementHistory extends ConsumerWidget {
  final String productId;
  const _MovementHistory({required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movementsAsync = ref.watch(stockMovementsProvider(productId));
    return movementsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: LinearProgressIndicator(),
      ),
      error: (err, _) => Text(
        friendlyError(err),
        style: AppTheme.jakarta(fontSize: 12, color: AppColors.error),
      ),
      data: (movements) {
        if (movements.isEmpty) {
          return Text(
            'Sem movimentações registradas.',
            style: AppTheme.jakarta(fontSize: 12, color: AppColors.textMuted),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HISTÓRICO',
              style: AppTheme.jakarta(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted,
              ).copyWith(letterSpacing: 1.2),
            ),
            const SizedBox(height: 6),
            ...movements.take(20).map((m) {
              final isEntrada = m.type == StockMovement.typeEntrada;
              final isSaida = m.type == StockMovement.typeSaida;
              final c = isEntrada
                  ? AppColors.staleOk
                  : (isSaida ? AppColors.staleCrit : AppColors.textSecondary);
              final sign = isEntrada ? '+' : (isSaida ? '−' : '=');
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: c.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusFull,
                        ),
                      ),
                      child: Text(
                        StockConstants.typeLabel(m.type),
                        style: AppTheme.jakarta(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: c,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        m.reason ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.jakarta(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      AppDateUtils.formatDate(m.createdAt),
                      style: AppTheme.jakarta(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$sign${_InventoryTile._fmt(m.quantity)}',
                      style: AppTheme.numeric(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: c,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _MovementDialog extends ConsumerStatefulWidget {
  final Product product;
  const _MovementDialog({required this.product});

  @override
  ConsumerState<_MovementDialog> createState() => _MovementDialogState();
}

class _MovementDialogState extends ConsumerState<_MovementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  final _reasonController = TextEditingController();
  String _type = StockMovement.typeEntrada;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _qtyController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final qty = double.tryParse(_qtyController.text.replaceAll(',', '.')) ?? 0;
    try {
      await ref
          .read(stockProvider.notifier)
          .registerMovement(
            productId: widget.product.id,
            type: _type,
            quantity: qty,
            reason: _reasonController.text.trim().isEmpty
                ? null
                : _reasonController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Movimentar: ${widget.product.name}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Text(_error!, style: AppTheme.jakarta(color: AppColors.error)),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: StockConstants.types
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(StockConstants.typeLabel(t)),
                    ),
                  )
                  .toList(),
              onChanged: (v) =>
                  setState(() => _type = v ?? StockConstants.types.first),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _qtyController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: _type == StockMovement.typeAjuste
                    ? 'Novo valor de estoque'
                    : 'Quantidade',
              ),
              validator: (v) {
                final parsed = double.tryParse((v ?? '').replaceAll(',', '.'));
                if (parsed == null) return 'Informe um número';
                if (_type != StockMovement.typeAjuste && parsed <= 0) {
                  return 'Quantidade deve ser maior que zero';
                }
                if (parsed < 0) return 'Não pode ser negativo';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(labelText: 'Motivo (opcional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Registrar'),
        ),
      ],
    );
  }
}
