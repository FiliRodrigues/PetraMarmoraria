import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_messages.dart';
import '../../core/utils/validators.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../widgets/widgets.dart';

/// Screen to create or edit a product/material.
class ProductFormScreen extends ConsumerStatefulWidget {
  final String? id;

  const ProductFormScreen({super.key, this.id});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();

  String _selectedType = 'marmore';
  String _selectedUnit = 'm2';
  bool _isEditing = false;
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _types = [
    'marmore',
    'granito',
    'quartzo',
    'ardosia',
    'outro',
  ];

  final List<String> _units = ['m2', 'unidade', 'ml'];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.id != null;
    if (_isEditing) {
      _loadProductData();
    }
  }

  void _loadProductData() {
    final productsState = ref.read(productProvider);
    productsState.maybeWhen(
      data: (list) {
        try {
          final product = list.firstWhere((p) => p.id == widget.id);
          _nameController.text = product.name;
          _priceController.text = product.unitPrice.toStringAsFixed(2);
          _stockController.text = product.stockQuantity.toString();
          _minStockController.text = product.minStock.toString();
          _selectedType = _types.contains(product.type.toLowerCase())
              ? product.type.toLowerCase()
              : 'marmore';
          _selectedUnit = _units.contains(product.unit.toLowerCase())
              ? product.unit.toLowerCase()
              : 'm2';
        } catch (_) {
          _errorMessage = 'Produto não encontrado no cache.';
        }
      },
      orElse: () {
        _errorMessage = 'Erro: Catálogo de produtos não carregada.';
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final price =
        double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0.0;
    final minStock =
        double.tryParse(_minStockController.text.replaceAll(',', '.')) ?? 0.0;
    // Estoque atual só é definido na criação; na edição é controlado por
    // movimentações (não sobrescrevemos pelo formulário).
    final initialStock =
        double.tryParse(_stockController.text.replaceAll(',', '.')) ?? 0.0;

    final existing = _isEditing
        ? ref
              .read(productProvider)
              .value
              ?.cast<Product?>()
              .firstWhere((p) => p?.id == widget.id, orElse: () => null)
        : null;

    final product = Product(
      id: _isEditing ? widget.id! : const Uuid().v4(),
      name: _nameController.text.trim(),
      type: _selectedType,
      unitPrice: price,
      unit: _selectedUnit,
      stockQuantity: _isEditing
          ? (existing?.stockQuantity ?? 0.0)
          : initialStock,
      minStock: minStock,
      active: true,
      createdAt: DateTime.now(),
    );

    try {
      if (_isEditing) {
        await ref.read(productProvider.notifier).updateProduct(product);
      } else {
        await ref.read(productProvider.notifier).addProduct(product);
      }
      if (mounted) {
        context.pop();
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

  Future<void> _confirmDelete() async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Excluir Material',
      content:
          'Tem certeza que deseja excluir este material? Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      confirmColor: AppColors.error,
    );
    if (!ok) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(productProvider.notifier).deleteProduct(widget.id!);
      if (mounted) {
        AppSnackbar.success(context, 'Material excluído.');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = friendlyError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'Salvando material...',
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEditing ? 'Editar Material' : 'Cadastrar Novo Material',
          ),
          actions: [
            if (_isEditing)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Excluir Material',
                onPressed: _isLoading ? null : _confirmDelete,
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
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

                        // Material Name
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nome do Material *',
                            prefixIcon: Icon(Icons.texture),
                            hintText:
                                'Ex: Mármore Carrara, Granito Preto São Gabriel',
                          ),
                          validator: (val) => Validators.validateRequired(
                            val,
                            'Nome do material',
                          ),
                        ),
                        const SizedBox(height: 16.0),

                        // Type & Unit
                        AdaptiveFieldRow(
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: _selectedType,
                              decoration: InputDecoration(
                                labelText: 'Tipo *',
                                prefixIcon: Icon(Icons.category),
                              ),
                              items: _types.map((t) {
                                return DropdownMenuItem<String>(
                                  value: t,
                                  child: Text(t.toUpperCase()),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedType = val;
                                  });
                                }
                              },
                            ),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedUnit,
                              decoration: InputDecoration(
                                labelText: 'Unidade *',
                                prefixIcon: Icon(Icons.straighten),
                              ),
                              items: _units.map((u) {
                                return DropdownMenuItem<String>(
                                  value: u,
                                  child: Text(u == 'm2' ? 'm²' : u),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedUnit = val;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),

                        // Preço base
                        TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Preço Base (R\$) *',
                            prefixIcon: Icon(Icons.monetization_on),
                            hintText: '0.00',
                          ),
                          validator: (val) =>
                              Validators.validateMoney(val, 'Preço base'),
                        ),
                        const SizedBox(height: 16.0),

                        // Estoque atual (só criação) + Estoque mínimo
                        AdaptiveFieldRow(
                          children: [
                            if (!_isEditing)
                              TextFormField(
                                controller: _stockController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'Estoque atual',
                                  prefixIcon: Icon(Icons.inventory_2),
                                  hintText: '0',
                                ),
                                validator: (v) =>
                                    Validators.validateNonNegativeOptional(
                                      v,
                                      'Estoque atual',
                                    ),
                              ),
                            TextFormField(
                              controller: _minStockController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Estoque mínimo',
                                prefixIcon: Icon(Icons.warning_amber),
                                hintText: '0',
                              ),
                              validator: (v) =>
                                  Validators.validateNonNegativeOptional(
                                    v,
                                    'Estoque mínimo',
                                  ),
                            ),
                          ],
                        ),
                        if (_isEditing) ...[
                          const SizedBox(height: 8.0),
                          Text(
                            'O estoque atual é alterado por movimentações na tela de Estoque.',
                            style: AppTheme.jakarta(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                        const SizedBox(height: 32.0),

                        // Actions Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => context.pop(),
                              child: Text(
                                'Cancelar',
                                style: AppTheme.jakarta(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16.0),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _saveProduct,
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
        ),
      ),
    );
  }
}
