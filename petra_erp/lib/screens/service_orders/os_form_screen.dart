import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/os_status.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/validators.dart';
import '../../models/models.dart';
import '../../providers/customer_provider.dart';
import '../../providers/os_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/widgets.dart';

/// Screen to create or edit a Service Order (Ordem de Serviço).
/// Features a searchable customer autocomplete, dynamic measurements table,
/// blueprint file attachment mock, and automatic queue placement.
class OSFormScreen extends ConsumerStatefulWidget {
  final String? id;

  const OSFormScreen({
    super.key,
    this.id,
  });

  @override
  ConsumerState<OSFormScreen> createState() => _OSFormScreenState();
}

class _OSFormScreenState extends ConsumerState<OSFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _customerSearchController = TextEditingController();
  final _materialController = TextEditingController();
  final _edgeTypeController = TextEditingController();
  final _valueController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _drawingUrlController = TextEditingController();

  Customer? _selectedCustomer;
  List<Map<String, String>> _measurements = [];
  DateTime? _scheduledDate;
  bool _isEditing = false;
  bool _isLoading = false;
  String? _errorMessage;
  String _currentStatus = OSStatus.orcamento;
  int _queuePosition = 1;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.id != null;
    
    // Check if we need to pre-link customer from query parameters
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_isEditing) {
        final state = GoRouterState.of(context);
        final preLinkedCustomerId = state.uri.queryParameters['customerId'];
        if (preLinkedCustomerId != null) {
          _preLinkCustomer(preLinkedCustomerId);
        }
      }
    });

    if (_isEditing) {
      _loadOrderData();
    } else {
      // Default empty measurement row
      _addMeasurementRow();
    }
  }
  void _preLinkCustomer(String customerId) {
    final customersState = ref.read(customerProvider);
    customersState.maybeWhen(
      data: (list) {
        final index = list.indexWhere((c) => c.id == customerId);
        if (index != -1) {
          final match = list[index];
          setState(() {
            _selectedCustomer = match;
            _customerSearchController.text = match.name;
          });
        }
      },
      orElse: () {},
    );
  }

  void _loadOrderData() {
    final ordersState = ref.read(osProvider);
    ordersState.maybeWhen(
      data: (list) {
        try {
          final order = list.firstWhere((o) => o.id == widget.id);
          _materialController.text = order.material ?? '';
          _edgeTypeController.text = order.edgeType ?? '';
          _valueController.text = order.totalValue.toStringAsFixed(2);
          _descriptionController.text = order.description;
          _drawingUrlController.text = order.drawingUrl ?? '';
          _currentStatus = order.status;
          _queuePosition = order.queuePosition;
          _scheduledDate = order.scheduledDate;

          // Customer
          _preLinkCustomer(order.customerId);

          // Parse measurements
          final List<Map<String, String>> parsed = [];
          final measurements = order.measurements;
          if (measurements.containsKey('items') && measurements['items'] is List) {
            final items = measurements['items'] as List;
            for (final item in items) {
              if (item is Map) {
                parsed.add({
                  'width': (item['width'] ?? item['largura'] ?? '').toString(),
                  'height': (item['height'] ?? item['altura'] ?? '').toString(),
                  'thickness': (item['thickness'] ?? item['espessura'] ?? '').toString(),
                  'format': (item['format'] ?? item['formato'] ?? '').toString(),
                  'details': (item['details'] ?? item['detalhes'] ?? '').toString(),
                });
              }
            }
          }
          setState(() {
            _measurements = parsed.isEmpty ? [{'width': '', 'height': '', 'thickness': '', 'format': '', 'details': ''}] : parsed;
          });
        } catch (_) {
          _errorMessage = 'Ordem de serviço não encontrada no cache.';
        }
      },
      orElse: () {
        _errorMessage = 'Erro: Lista de OS não carregada.';
      },
    );
  }

  @override
  void dispose() {
    _customerSearchController.dispose();
    _materialController.dispose();
    _edgeTypeController.dispose();
    _valueController.dispose();
    _descriptionController.dispose();
    _drawingUrlController.dispose();
    super.dispose();
  }

  void _addMeasurementRow() {
    setState(() {
      _measurements.add({
        'width': '',
        'height': '',
        'thickness': '',
        'format': '',
        'details': '',
      });
    });
  }

  void _removeMeasurementRow(int index) {
    if (_measurements.length <= 1) return;
    setState(() {
      _measurements.removeAt(index);
    });
  }

  Future<void> _pickScheduledDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('pt', 'BR'),
      initialDate: _scheduledDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      helpText: 'Data de entrega prevista',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    if (picked != null) {
      setState(() => _scheduledDate = picked);
    }
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCustomer == null) {
      setState(() {
        _errorMessage = 'Por favor, selecione um cliente válido da lista.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final val = double.tryParse(_valueController.text.replaceAll(',', '.')) ?? 0.0;

    // Build measurements map structure
    final measurementsMap = {
      'items': _measurements.map((m) => {
        'width': m['width'],
        'height': m['height'],
        'thickness': m['thickness'],
        'format': m['format'],
        'details': m['details'],
      }).toList()
    };

    // Calculate queue position if creating
    int finalQueuePosition = _queuePosition;
    if (!_isEditing) {
      final orders = ref.read(osProvider).value ?? [];
      finalQueuePosition = orders.isEmpty 
          ? 1 
          : orders.map((o) => o.queuePosition).reduce((a, b) => a > b ? a : b) + 1;
    }

    final order = ServiceOrder(
      id: _isEditing ? widget.id! : const Uuid().v4(),
      displayNumber: 0, // Auto-generated by Postgres serial column
      customerId: _selectedCustomer!.id,
      customerName: _selectedCustomer!.name,
      material: _materialController.text.trim().isEmpty ? null : _materialController.text.trim(),
      edgeType: _edgeTypeController.text.trim().isEmpty ? null : _edgeTypeController.text.trim(),
      status: _currentStatus,
      queuePosition: finalQueuePosition,
      description: _descriptionController.text.trim(),
      totalValue: val,
      measurements: measurementsMap,
      drawingUrl: _drawingUrlController.text.trim().isEmpty ? null : _drawingUrlController.text.trim(),
      scheduledDate: _scheduledDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      statusChangedAt: DateTime.now(),
    );

    try {
      if (_isEditing) {
        await ref.read(osProvider.notifier).updateOrder(order);
      } else {
        await ref.read(osProvider.notifier).createOrder(order);
      }
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erro ao salvar OS: $e';
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
    final customersState = ref.watch(customerProvider);
    final productsState = ref.watch(productProvider);

    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'Salvando ordem de serviço...',
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Editar OS' : 'Criar Nova OS'),
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
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                    ],

                    // 1. Searchable Customer Autocomplete
                    customersState.when(
                      data: (customers) {
                        return Autocomplete<Customer>(
                          initialValue: TextEditingValue(text: _selectedCustomer?.name ?? ''),
                          optionsBuilder: (textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return customers;
                            }
                            return customers.where((c) =>
                                c.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                          },
                          displayStringForOption: (c) => c.name,
                          onSelected: (Customer selection) {
                            setState(() {
                              _selectedCustomer = selection;
                            });
                          },
                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: 'Cliente *',
                                prefixIcon: Icon(Icons.person),
                                hintText: 'Digite o nome do cliente...',
                              ),
                              validator: (val) {
                                if (_selectedCustomer == null) {
                                  return 'Selecione um cliente válido da lista';
                                }
                                return null;
                              },
                            );
                          },
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (err, _) => Text('Erro ao carregar clientes: $err', style: const TextStyle(color: AppColors.error)),
                    ),
                    const SizedBox(height: 16.0),

                    // 2. Material/Product and Finishing type
                    Row(
                      children: [
                        // Searchable materials catalog dropdown
                        Expanded(
                          child: productsState.when(
                            data: (products) {
                              return DropdownButtonFormField<String>(
                                initialValue: products.any((p) => p.name == _materialController.text)
                                    ? _materialController.text 
                                    : null,
                                decoration: InputDecoration(
                                  labelText: 'Material / Pedra',
                                  prefixIcon: Icon(Icons.texture),
                                ),
                                hint: const Text('Selecione do catálogo'),
                                items: products.map((p) {
                                  return DropdownMenuItem<String>(
                                    value: p.name,
                                    child: Text(p.name),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _materialController.text = val;
                                      
                                      // Suggest pricing based on material base price
                                      final prod = products.firstWhere((p) => p.name == val);
                                      _valueController.text = prod.unitPrice.toStringAsFixed(2);
                                    });
                                  }
                                },
                              );
                            },
                            loading: () => const LinearProgressIndicator(),
                            error: (err, _) => TextFormField(
                              controller: _materialController,
                              decoration: InputDecoration(
                                labelText: 'Material / Pedra',
                                prefixIcon: Icon(Icons.texture),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16.0),

                        // Edge/Finishing Type
                        Expanded(
                          child: TextFormField(
                            controller: _edgeTypeController,
                             decoration: InputDecoration(
                              labelText: 'Tipo de Acabamento',
                              prefixIcon: Icon(Icons.border_style),
                              hintText: 'Bisotado, Meia Cana, 45º...',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),

                    // 3. Price Value (Mask input)
                    TextFormField(
                      controller: _valueController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Valor Total da OS (R\$) *',
                        prefixIcon: Icon(Icons.monetization_on),
                        hintText: '0.00',
                      ),
                      validator: (val) => Validators.validateRequired(val, 'Valor da OS'),
                    ),
                    const SizedBox(height: 16.0),

                    // 3b. Data de entrega prevista (opcional)
                    InkWell(
                      onTap: _pickScheduledDate,
                      borderRadius: BorderRadius.circular(8),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Data de entrega prevista',
                          prefixIcon: const Icon(Icons.event),
                          suffixIcon: _scheduledDate != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  tooltip: 'Limpar data',
                                  onPressed: () => setState(() => _scheduledDate = null),
                                )
                              : const Icon(Icons.arrow_drop_down),
                        ),
                        child: Text(
                          _scheduledDate != null
                              ? AppDateUtils.formatDate(_scheduledDate)
                              : 'Selecione uma data (opcional)',
                          style: TextStyle(
                            fontSize: 14,
                            color: _scheduledDate != null ? AppColors.primary : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // 4. Measurements dynamic grid section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Detalhamento de Medições',
                          style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        TextButton.icon(
                          onPressed: _addMeasurementRow,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Adicionar Linha'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),

                    // Measurements list fields
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _measurements.length,
                      itemBuilder: (context, index) {
                        final m = _measurements[index];
                        return Card(
                          color: Colors.grey[50],
                          margin: const EdgeInsets.only(bottom: 12.0),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: m['width'],
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(labelText: 'Largura (m)', contentPadding: EdgeInsets.all(8)),
                                        onChanged: (val) => m['width'] = val,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: m['height'],
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(labelText: 'Altura (m)', contentPadding: EdgeInsets.all(8)),
                                        onChanged: (val) => m['height'] = val,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: m['thickness'],
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(labelText: 'Espessura (cm)', contentPadding: EdgeInsets.all(8)),
                                        onChanged: (val) => m['thickness'] = val,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: AppColors.error),
                                      onPressed: () => _removeMeasurementRow(index),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: m['format'],
                                        decoration: const InputDecoration(labelText: 'Formato', contentPadding: EdgeInsets.all(8)),
                                        onChanged: (val) => m['format'] = val,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        initialValue: m['details'],
                                        decoration: const InputDecoration(labelText: 'Detalhes/Recortes', contentPadding: EdgeInsets.all(8)),
                                        onChanged: (val) => m['details'] = val,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16.0),

                    // 5. Drawing Sketch Attachment URL mock input
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _drawingUrlController,
                            decoration: const InputDecoration(
                              labelText: 'URL da Imagem do Desenho / Croqui',
                              prefixIcon: Icon(Icons.image),
                              hintText: 'https://...',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Mock a file picker select that updates with a template marble blueprint URL
                            setState(() {
                              _drawingUrlController.text = 
                                  'https://images.unsplash.com/photo-1588854337236-6889d631faa8?q=80&w=600';
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Desenho anexado (simulado)!')),
                            );
                          },
                          icon: const Icon(Icons.file_upload),
                          label: const Text('Anexar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24.0),

                    // 6. Description / Notes
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Descrição Geral do Serviço / Observações da Produção',
                        prefixIcon: Icon(Icons.description),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 32.0),

                    // Actions Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => context.pop(),
                          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                        ),
                        const SizedBox(width: 16.0),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _saveOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                          ),
                          child: Text(_isEditing ? 'SALVAR ALTERAÇÕES' : 'SALVAR ORDEM DE SERVIÇO'),
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
