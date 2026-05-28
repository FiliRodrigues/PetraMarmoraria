import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

/// Screen to create or edit a product/material.
class ProductFormScreen extends ConsumerStatefulWidget {
  final String? id;

  const ProductFormScreen({
    super.key,
    this.id,
  });

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  String _selectedType = 'marmore';
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

  @override
  void initState() {
    super.initState();
    _isEditing = widget.id != null;
    if (_isEditing) {
      _loadProductData();
    }
  }

  void _loadProductData() async {
    final productsState = ref.read(productProvider);
    productsState.maybeWhen(
      data: (list) {
        final idx = list.indexWhere((p) => p.id == widget.id);
        if (idx != -1) {
          _populateProductForm(list[idx]);
          return;
        }
      },
      orElse: () {},
    );
    // Fallback: fetch from API
    try {
      final service = ref.read(productServiceProvider);
      final product = await service.getProductById(widget.id!);
      _populateProductForm(product);
    } catch (e) {
      setState(() { _errorMessage = 'Erro ao carregar produto: $e'; });
    }
  }

  void _populateProductForm(Product product) {
    _nameController.text = product.name;
    _priceController.text = product.unitPrice.toStringAsFixed(2);
    _selectedType = _types.contains(product.type.toLowerCase())
        ? product.type.toLowerCase()
        : 'marmore';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final price = double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0.0;

    final product = Product(
      id: _isEditing ? widget.id! : const Uuid().v4(),
      name: _nameController.text.trim(),
      type: _selectedType,
      unitPrice: price,
      unit: 'm2',
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
      setState(() {
        _errorMessage = 'Erro ao salvar produto: $e';
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
      message: 'Salvando material...',
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Editar Material' : 'Cadastrar Novo Material'),
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

                    // Material Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nome do Material *',
                        prefixIcon: Icon(LucideIcons.layers, size: 16),
                        hintText: 'Ex: Mármore Carrara, Granito Preto São Gabriel',
                      ),
                      validator: (val) => Validators.validateRequired(val, 'Nome do material'),
                    ),
                    const SizedBox(height: 16.0),

                    // Type & Price
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedType,
                            decoration: InputDecoration(
                              labelText: 'Tipo *',
                              prefixIcon: Icon(LucideIcons.tag, size: 16),
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
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Preço Base por m\u00B2 (R\$) *',
                              prefixIcon: Icon(LucideIcons.dollarSign, size: 16),
                              hintText: '0.00',
                            ),
                            validator: (val) {
                              final req = Validators.validateRequired(val, 'Preço base');
                              if (req != null) return req;
                              final parsed = double.tryParse(val!.replaceAll(',', '.'));
                              if (parsed == null || parsed <= 0) {
                                return 'Insira um valor maior que zero';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32.0),

                    // Actions Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => context.pop(),
                          child: Text('Cancelar', style: AppTheme.jakarta(fontSize: 13, color: AppColors.textMuted)),
                        ),
                        const SizedBox(width: 16.0),
                        ElevatedButton(
                          onPressed: _saveProduct,
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
