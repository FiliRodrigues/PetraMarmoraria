import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_messages.dart';
import '../../core/utils/validators.dart';
import '../../models/company_info.dart';
import '../../providers/auth_provider.dart';
import '../../providers/company_provider.dart';
import '../../providers/supabase_provider.dart';
import '../../widgets/widgets.dart';

/// Tela de configurações da empresa (apenas admin). Edita os dados que saem no
/// cabeçalho do PDF e no menu lateral, além dos prazos padrão.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _paymentTermsController = TextEditingController();

  String? _logoUrl;
  bool _loaded = false;
  bool _isLoading = false;
  String? _errorMessage;

  void _fill(CompanyInfo info) {
    _nameController.text = info.name;
    _cnpjController.text = info.cnpj ?? '';
    _addressController.text = info.address ?? '';
    _phoneController.text = info.phone ?? '';
    _emailController.text = info.email ?? '';
    _deadlineController.text = info.defaultDeadlineDays.toString();
    _paymentTermsController.text = info.defaultPaymentTermsDays.toString();
    _logoUrl = info.logoUrl;
    _loaded = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cnpjController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _deadlineController.dispose();
    _paymentTermsController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;
      setState(() => _isLoading = true);
      final bytes = await picked.readAsBytes();
      final url = await ref
          .read(storageServiceProvider)
          .uploadImage(
            bytes: bytes,
            folder: 'logos',
            fileName: picked.name,
            contentType: picked.mimeType ?? 'image/jpeg',
          );
      setState(() => _logoUrl = url);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final info = CompanyInfo(
      name: _nameController.text.trim(),
      cnpj: _cnpjController.text.trim().isEmpty
          ? null
          : _cnpjController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      logoUrl: _logoUrl,
      defaultDeadlineDays: int.tryParse(_deadlineController.text.trim()) ?? 15,
      defaultPaymentTermsDays:
          int.tryParse(_paymentTermsController.text.trim()) ?? 30,
    );

    try {
      await ref.read(companyProvider.notifier).save(info);
      if (mounted) {
        AppSnackbar.success(context, 'Configurações salvas com sucesso!');
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(currentProfileProvider).value?.isAdmin ?? false;
    final companyAsync = ref.watch(companyProvider);

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Configurações')),
        body: const Center(
          child: Text('Apenas administradores podem acessar as configurações.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações da Empresa')),
      body: companyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(friendlyError(err))),
        data: (info) {
          if (!_loaded) _fill(info);
          return LoadingOverlay(
            isLoading: _isLoading,
            message: 'Salvando...',
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
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
                              const SizedBox(height: 16),
                            ],

                            // Logo
                            Row(
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusLg,
                                    ),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child:
                                      _logoUrl != null && _logoUrl!.isNotEmpty
                                      ? Image.network(
                                          _logoUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => const Icon(
                                            Icons.business,
                                            color: AppColors.textMuted,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.business,
                                          color: AppColors.textMuted,
                                        ),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _pickLogo,
                                  icon: const Icon(Icons.upload),
                                  label: const Text('Enviar logo'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nome da Empresa *',
                                prefixIcon: Icon(Icons.business),
                              ),
                              validator: (v) => Validators.validateRequired(
                                v,
                                'Nome da empresa',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _cnpjController,
                              decoration: const InputDecoration(
                                labelText: 'CNPJ',
                                prefixIcon: Icon(Icons.badge),
                              ),
                              validator: Validators.validateCpfCnpj,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: 'Endereço',
                                prefixIcon: Icon(Icons.location_on),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Telefone',
                                prefixIcon: Icon(Icons.phone),
                              ),
                              validator: Validators.validatePhoneOptional,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'E-mail',
                                prefixIcon: Icon(Icons.email),
                              ),
                              validator: Validators.validateEmailOptional,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _deadlineController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Prazo padrão (dias)',
                                      prefixIcon: Icon(Icons.schedule),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _paymentTermsController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Vencimento padrão (dias)',
                                      prefixIcon: Icon(Icons.payments),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _save,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                  ),
                                  child: const Text('SALVAR'),
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
          );
        },
      ),
    );
  }
}
