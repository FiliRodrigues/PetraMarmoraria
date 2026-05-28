import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/company_info.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _companyFormKey = GlobalKey<FormState>();
  final _defaultsFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _logoUrlController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _paymentTermsController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCompanyInfo());
  }

  void _loadCompanyInfo() {
    final infoAsync = ref.read(companyInfoProvider);
    infoAsync.whenData((info) {
      if (info != null && mounted) {
        _populateForm(info);
      }
    });
  }

  void _populateForm(CompanyInfo info) {
    _nameController.text = info.name;
    _cnpjController.text = info.cnpj ?? '';
    _addressController.text = info.address ?? '';
    _phoneController.text = info.phone ?? '';
    _emailController.text = info.email ?? '';
    _logoUrlController.text = info.logoUrl ?? '';
    _deadlineController.text = info.defaultDeadlineDays.toString();
    _paymentTermsController.text = info.defaultPaymentTermsDays.toString();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _cnpjController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _logoUrlController.dispose();
    _deadlineController.dispose();
    _paymentTermsController.dispose();
    super.dispose();
  }

  Future<void> _saveCompanyTab() async {
    if (!_companyFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final current = await ref.read(companyInfoProvider.future);
      final info = CompanyInfo(
        id: 1,
        name: _nameController.text.trim(),
        cnpj: _cnpjController.text.trim().isEmpty ? null : _cnpjController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        logoUrl: _logoUrlController.text.trim().isEmpty ? null : _logoUrlController.text.trim(),
        defaultDeadlineDays: current?.defaultDeadlineDays ?? 15,
        defaultPaymentTermsDays: current?.defaultPaymentTermsDays ?? 30,
        updatedAt: DateTime.now(),
      );

      final service = ref.read(settingsServiceProvider);
      await service.updateCompanyInfo(info);
      ref.invalidate(companyInfoProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informações salvas com sucesso!')),
        );
      }
    } catch (e) {
      setState(() { _errorMessage = 'Erro ao salvar: $e'; });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _saveDefaultsTab() async {
    if (!_defaultsFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final current = await ref.read(companyInfoProvider.future);
      final info = CompanyInfo(
        id: 1,
        name: current?.name ?? '',
        cnpj: current?.cnpj,
        address: current?.address,
        phone: current?.phone,
        email: current?.email,
        logoUrl: current?.logoUrl,
        defaultDeadlineDays: int.tryParse(_deadlineController.text.trim()) ?? 15,
        defaultPaymentTermsDays: int.tryParse(_paymentTermsController.text.trim()) ?? 30,
        updatedAt: DateTime.now(),
      );

      final service = ref.read(settingsServiceProvider);
      await service.updateCompanyInfo(info);
      ref.invalidate(companyInfoProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Padrões salvos com sucesso!')),
        );
      }
    } catch (e) {
      setState(() { _errorMessage = 'Erro ao salvar: $e'; });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final infoAsync = ref.watch(companyInfoProvider);

    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'Salvando informações...',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Configurações'),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.accent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.5),
            tabs: const [
              Tab(text: 'EMPRESA'),
              Tab(text: 'PADRÕES'),
            ],
          ),
        ),
        body: infoAsync.when(
          data: (info) {
            if (info == null && mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _loadCompanyInfo());
            }
            return _buildForm(info);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Erro ao carregar configurações: $err',
                style: AppTheme.jakarta(fontSize: 13, color: AppColors.error),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(CompanyInfo? info) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildCompanyTab(info),
        _buildDefaultsTab(info),
      ],
    );
  }

  Widget _buildCompanyTab(CompanyInfo? info) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _companyFormKey,
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
                    labelText: 'Nome da Empresa *',
                    prefixIcon: Icon(LucideIcons.building2, size: 16),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nome da empresa é obrigatório';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cnpjController,
                        decoration: const InputDecoration(
                          labelText: 'CNPJ',
                          prefixIcon: Icon(LucideIcons.creditCard, size: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [PhoneInputFormatter()],
                        decoration: const InputDecoration(
                          labelText: 'Telefone',
                          prefixIcon: Icon(LucideIcons.phone, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(LucideIcons.mail, size: 16),
                  ),
                ),
                const SizedBox(height: 16.0),

                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Endereço',
                    prefixIcon: Icon(LucideIcons.mapPin, size: 16),
                  ),
                ),
                const SizedBox(height: 16.0),

                TextFormField(
                  controller: _logoUrlController,
                  decoration: const InputDecoration(
                    labelText: 'URL da Logo',
                    prefixIcon: Icon(LucideIcons.image, size: 16),
                    hintText: 'https://...',
                  ),
                ),
                const SizedBox(height: 32.0),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: _saveCompanyTab,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                      ),
                      child: const Text('SALVAR DADOS DA EMPRESA'),
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

  Widget _buildDefaultsTab(CompanyInfo? info) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _defaultsFormKey,
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
                  controller: _deadlineController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Prazo Padrão (dias)',
                    prefixIcon: Icon(LucideIcons.calendar, size: 16),
                    hintText: '15',
                  ),
                  validator: (val) {
                    if (val != null && val.isNotEmpty) {
                      final n = int.tryParse(val);
                      if (n == null || n < 1) {
                        return 'Informe um número válido de dias';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),

                TextFormField(
                  controller: _paymentTermsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Condição de Pagamento Padrão (dias)',
                    prefixIcon: Icon(LucideIcons.dollarSign, size: 16),
                    hintText: '30',
                  ),
                  validator: (val) {
                    if (val != null && val.isNotEmpty) {
                      final n = int.tryParse(val);
                      if (n == null || n < 1) {
                        return 'Informe um número válido de dias';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32.0),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: _saveDefaultsTab,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                      ),
                      child: const Text('SALVAR PADRÕES'),
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
