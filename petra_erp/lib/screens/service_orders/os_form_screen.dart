import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/os_status.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/error_messages.dart';
import '../../core/utils/validators.dart';
import '../../models/models.dart';
import '../../providers/customer_provider.dart';
import '../../providers/os_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/supabase_provider.dart';
import '../../widgets/widgets.dart';

/// Screen to create or edit a Service Order (Ordem de Serviço).
/// Features a searchable customer autocomplete, dynamic measurements table,
/// blueprint file attachment mock, and automatic queue placement.
class OSFormScreen extends ConsumerStatefulWidget {
  final String? id;

  const OSFormScreen({super.key, this.id});

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
  final _budgetUrlController = TextEditingController();

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
          _budgetUrlController.text = order.budgetUrl ?? '';
          _currentStatus = order.status;
          _queuePosition = order.queuePosition;
          _scheduledDate = order.scheduledDate;

          // Customer
          _preLinkCustomer(order.customerId);

          // Parse measurements
          final List<Map<String, String>> parsed = [];
          final measurements = order.measurements;
          if (measurements.containsKey('items') &&
              measurements['items'] is List) {
            final items = measurements['items'] as List;
            for (final item in items) {
              if (item is Map) {
                parsed.add({
                  'width': (item['width'] ?? item['largura'] ?? '').toString(),
                  'height': (item['height'] ?? item['altura'] ?? '').toString(),
                  'thickness': (item['thickness'] ?? item['espessura'] ?? '')
                      .toString(),
                  'format': (item['format'] ?? item['formato'] ?? '')
                      .toString(),
                  'details': (item['details'] ?? item['detalhes'] ?? '')
                      .toString(),
                });
              }
            }
          }
          setState(() {
            _measurements = parsed.isEmpty
                ? [
                    {
                      'width': '',
                      'height': '',
                      'thickness': '',
                      'format': '',
                      'details': '',
                    },
                  ]
                : parsed;
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
    _budgetUrlController.dispose();
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

  Future<void> _pickAndUploadDrawing() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        if (mounted) {
          setState(
            () => _errorMessage = 'Não foi possível ler o arquivo selecionado.',
          );
        }
        return;
      }
      setState(() => _isLoading = true);
      final isPdf = file.extension?.toLowerCase() == 'pdf';
      final contentType = isPdf ? 'application/pdf' : 'image/jpeg';
      final url = await ref
          .read(storageServiceProvider)
          .uploadFile(
            bytes: bytes,
            folder: 'desenhos',
            fileName: file.name,
            contentType: contentType,
          );
      setState(() => _drawingUrlController.text = url);
      if (mounted) {
        AppSnackbar.success(context, 'Desenho anexado!');
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadBudget() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        if (mounted) {
          setState(
            () => _errorMessage = 'Não foi possível ler o arquivo selecionado.',
          );
        }
        return;
      }
      setState(() => _isLoading = true);
      final isPdf = file.extension?.toLowerCase() == 'pdf';
      final contentType = isPdf ? 'application/pdf' : 'image/jpeg';
      final url = await ref
          .read(storageServiceProvider)
          .uploadFile(
            bytes: bytes,
            folder: 'orcamentos',
            fileName: file.name,
            contentType: contentType,
          );
      setState(() => _budgetUrlController.text = url);
      if (mounted) {
        AppSnackbar.success(context, 'Orçamento anexado!');
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

    final val =
        double.tryParse(_valueController.text.replaceAll(',', '.')) ?? 0.0;

    // Build measurements map structure
    final measurementsMap = {
      'items': _measurements
          .map(
            (m) => {
              'width': m['width'],
              'height': m['height'],
              'thickness': m['thickness'],
              'format': m['format'],
              'details': m['details'],
            },
          )
          .toList(),
    };

    // Calculate queue position if creating
    int finalQueuePosition = _queuePosition;
    if (!_isEditing) {
      final orders = ref.read(osProvider).value ?? [];
      finalQueuePosition = orders.isEmpty
          ? 1
          : orders.map((o) => o.queuePosition).reduce((a, b) => a > b ? a : b) +
                1;
    }

    final order = ServiceOrder(
      id: _isEditing ? widget.id! : const Uuid().v4(),
      displayNumber: 0, // Auto-generated by Postgres serial column
      customerId: _selectedCustomer!.id,
      customerName: _selectedCustomer!.name,
      material: _materialController.text.trim().isEmpty
          ? null
          : _materialController.text.trim(),
      edgeType: _edgeTypeController.text.trim().isEmpty
          ? null
          : _edgeTypeController.text.trim(),
      status: _currentStatus,
      queuePosition: finalQueuePosition,
      description: _descriptionController.text.trim(),
      totalValue: val,
      measurements: measurementsMap,
      drawingUrl: _drawingUrlController.text.trim().isEmpty
          ? null
          : _drawingUrlController.text.trim(),
      budgetUrl: _budgetUrlController.text.trim().isEmpty
          ? null
          : _budgetUrlController.text.trim(),
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

  Widget _buildAttachmentPreview(String url) {
    final isPdf = url.toLowerCase().endsWith('.pdf');
    if (isPdf) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.picture_as_pdf, size: 28, color: AppColors.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                url.split('/').last,
                style: AppTheme.jakarta(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () => launchUrl(Uri.parse(url)),
              child: const Text('Abrir'),
            ),
          ],
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Image.network(
        url,
        height: 140,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customersState = ref.watch(customerProvider);
    final productsState = ref.watch(productProvider);

    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'Salvando ordem de serviço...',
      child: Scaffold(
        appBar: AppBar(title: Text(_isEditing ? 'Editar OS' : 'Criar Nova OS')),
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

                        // 1. Searchable Customer Autocomplete
                        customersState.when(
                          data: (customers) {
                            return Autocomplete<Customer>(
                              initialValue: TextEditingValue(
                                text: _selectedCustomer?.name ?? '',
                              ),
                              optionsBuilder: (textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return customers;
                                }
                                return customers.where(
                                  (c) => c.name.toLowerCase().contains(
                                    textEditingValue.text.toLowerCase(),
                                  ),
                                );
                              },
                              displayStringForOption: (c) => c.name,
                              onSelected: (Customer selection) {
                                setState(() {
                                  _selectedCustomer = selection;
                                });
                              },
                              fieldViewBuilder:
                                  (
                                    context,
                                    controller,
                                    focusNode,
                                    onFieldSubmitted,
                                  ) {
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
                          error: (err, _) => Text(
                            friendlyError(err),
                            style: AppTheme.jakarta(color: AppColors.error),
                          ),
                        ),
                        const SizedBox(height: 16.0),

                        // 2. Material/Product and Finishing type
                        AdaptiveFieldRow(
                          children: [
                            // Searchable materials catalog dropdown
                            productsState.when(
                              data: (products) {
                                return DropdownButtonFormField<String>(
                                  initialValue:
                                      products.any(
                                        (p) =>
                                            p.name == _materialController.text,
                                      )
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
                                      final prod = products
                                          .where((p) => p.name == val)
                                          .firstOrNull;
                                      setState(() {
                                        _materialController.text = val;

                                        // Suggest pricing based on material base price
                                        if (prod != null) {
                                          _valueController.text = prod.unitPrice
                                              .toStringAsFixed(2);
                                        }
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

                            // Edge/Finishing Type
                            TextFormField(
                              controller: _edgeTypeController,
                              decoration: InputDecoration(
                                labelText: 'Tipo de Acabamento',
                                prefixIcon: Icon(Icons.border_style),
                                hintText: 'Bisotado, Meia Cana, 45º...',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),

                        // 3. Price Value (Mask input)
                        TextFormField(
                          controller: _valueController,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Valor Total da OS (R\$) *',
                            prefixIcon: Icon(Icons.monetization_on),
                            hintText: '0.00',
                          ),
                          validator: (val) =>
                              Validators.validateMoney(val, 'Valor da OS'),
                        ),
                        const SizedBox(height: 16.0),

                        // 3b. Data de entrega prevista (opcional)
                        InkWell(
                          onTap: _pickScheduledDate,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Data de entrega prevista',
                              prefixIcon: const Icon(Icons.event),
                              suffixIcon: _scheduledDate != null
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      tooltip: 'Limpar data',
                                      onPressed: () =>
                                          setState(() => _scheduledDate = null),
                                    )
                                  : const Icon(Icons.arrow_drop_down),
                            ),
                            child: Text(
                              _scheduledDate != null
                                  ? AppDateUtils.formatDate(_scheduledDate)
                                  : 'Selecione uma data (opcional)',
                              style: AppTheme.jakarta(
                                fontSize: 14,
                                color: _scheduledDate != null
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24.0),

                        // 4. Measurements dynamic grid section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Detalhamento de Medições',
                              style: AppTheme.syne(
                                fontSize: 14.0,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
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
                                    AdaptiveFieldRow(
                                      gap: 8,
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: AppColors.error,
                                        ),
                                        onPressed: () =>
                                            _removeMeasurementRow(index),
                                      ),
                                      children: [
                                        TextFormField(
                                          initialValue: m['width'],
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Largura (m)',
                                            contentPadding: EdgeInsets.all(8),
                                          ),
                                          onChanged: (val) => m['width'] = val,
                                        ),
                                        TextFormField(
                                          initialValue: m['height'],
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Altura (m)',
                                            contentPadding: EdgeInsets.all(8),
                                          ),
                                          onChanged: (val) => m['height'] = val,
                                        ),
                                        TextFormField(
                                          initialValue: m['thickness'],
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Espessura (cm)',
                                            contentPadding: EdgeInsets.all(8),
                                          ),
                                          onChanged: (val) =>
                                              m['thickness'] = val,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    AdaptiveFieldRow(
                                      gap: 8,
                                      flex: const [1, 2],
                                      children: [
                                        TextFormField(
                                          initialValue: m['format'],
                                          decoration: const InputDecoration(
                                            labelText: 'Formato',
                                            contentPadding: EdgeInsets.all(8),
                                          ),
                                          onChanged: (val) => m['format'] = val,
                                        ),
                                        TextFormField(
                                          initialValue: m['details'],
                                          decoration: const InputDecoration(
                                            labelText: 'Detalhes/Recortes',
                                            contentPadding: EdgeInsets.all(8),
                                          ),
                                          onChanged: (val) =>
                                              m['details'] = val,
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

                        // 5. Drawing Sketch Attachment: upload real ou URL manual
                        AdaptiveFieldRow(
                          gap: 12,
                          trailing: ElevatedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : _pickAndUploadDrawing,
                            icon: const Icon(Icons.file_upload),
                            label: const Text('Anexar'),
                          ),
                          children: [
                            TextFormField(
                              controller: _drawingUrlController,
                              decoration: const InputDecoration(
                                labelText: 'URL do Desenho / Croqui',
                                prefixIcon: Icon(Icons.image),
                                hintText: 'Cole uma URL ou clique em Anexar',
                              ),
                            ),
                          ],
                        ),
                        if (_drawingUrlController.text.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildAttachmentPreview(
                            _drawingUrlController.text.trim(),
                          ),
                        ],
                        const SizedBox(height: 24.0),

                        // 5b. Budget Attachment
                        AdaptiveFieldRow(
                          gap: 12,
                          trailing: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _pickAndUploadBudget,
                            icon: const Icon(Icons.file_upload),
                            label: const Text('Anexar'),
                          ),
                          children: [
                            TextFormField(
                              controller: _budgetUrlController,
                              decoration: const InputDecoration(
                                labelText: 'URL do Orçamento',
                                prefixIcon: Icon(Icons.attach_money),
                                hintText: 'Cole uma URL ou clique em Anexar',
                              ),
                            ),
                          ],
                        ),
                        if (_budgetUrlController.text.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildAttachmentPreview(
                            _budgetUrlController.text.trim(),
                          ),
                        ],
                        const SizedBox(height: 24.0),

                        // 6. Description / Notes
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText:
                                'Descrição Geral do Serviço / Observações da Produção',
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
                              child: Text(
                                'Cancelar',
                                style: AppTheme.jakarta(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16.0),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _saveOrder,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32.0,
                                  vertical: 16.0,
                                ),
                              ),
                              child: Text(
                                _isEditing
                                    ? 'SALVAR ALTERAÇÕES'
                                    : 'SALVAR ORDEM DE SERVIÇO',
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
