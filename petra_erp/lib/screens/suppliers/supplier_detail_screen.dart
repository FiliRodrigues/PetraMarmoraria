import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/supplier_provider.dart';
import '../../widgets/widgets.dart';

class SupplierDetailScreen extends ConsumerWidget {
  final String id;
  const SupplierDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersAsync = ref.watch(supplierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Fornecedor'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.edit, size: 18),
            tooltip: 'Editar Fornecedor',
            onPressed: () => context.push('/suppliers/$id/edit'),
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
            tooltip: 'Excluir Fornecedor',
            onPressed: () async {
              final suppliers = suppliersAsync.value ?? [];
              final supplier = suppliers.where((s) => s.id == id).firstOrNull;
              if (supplier == null) return;
              final confirm = await ConfirmDialog.show(
                context,
                title: 'Confirmar Exclusão',
                content: 'Deseja realmente excluir o fornecedor "${supplier.name}"?',
                confirmColor: AppColors.error,
              );
              if (confirm) {
                try {
                  await ref.read(supplierProvider.notifier).deleteSupplier(id);
                  if (context.mounted) context.pop();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao excluir fornecedor: $e'),
                        backgroundColor: AppColors.error),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: suppliersAsync.when(
        data: (suppliers) {
          final index = suppliers.indexWhere((s) => s.id == id);
          if (index == -1) {
            return Center(child: Text('Fornecedor não encontrado.', style: AppTheme.jakarta(color: AppColors.textMuted)));
          }
          final supplier = suppliers[index];
          final initials = supplier.name.isNotEmpty ? supplier.name[0].toUpperCase() : 'F';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: AppColors.border),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                            alignment: Alignment.center,
                            child: Text(initials,
                              style: AppTheme.syne(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(supplier.name,
                                  style: AppTheme.syne(fontSize: 18, fontWeight: FontWeight.w800)),
                                if (supplier.cpfCnpj != null) ...[
                                  const SizedBox(height: 3),
                                  Text(supplier.cpfCnpj!,
                                    style: AppTheme.jakarta(fontSize: 12, color: AppColors.textMuted)),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _InfoItem(LucideIcons.phone, 'Telefone Principal',
                              Formatters.formatPhone(supplier.phone))),
                          if (supplier.phone2 != null)
                            Expanded(child: _InfoItem(LucideIcons.smartphone, 'Telefone 2',
                                Formatters.formatPhone(supplier.phone2!))),
                        ],
                      ),
                      if (supplier.email != null || supplier.contactPerson != null) ...[
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (supplier.email != null)
                              Expanded(child: _InfoItem(LucideIcons.mail, 'E-mail', supplier.email!)),
                            if (supplier.contactPerson != null)
                              Expanded(child: _InfoItem(LucideIcons.user, 'Contato', supplier.contactPerson!)),
                          ],
                        ),
                      ],
                      if (supplier.address != null || supplier.city != null) ...[
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (supplier.address != null)
                              Expanded(child: _InfoItem(LucideIcons.mapPin, 'Endereço', supplier.address!)),
                            if (supplier.city != null)
                              Expanded(child: _InfoItem(LucideIcons.building2, 'Cidade',
                                  '${supplier.city} / ${supplier.state}')),
                          ],
                        ),
                      ],
                      if (supplier.notes != null) ...[
                        const SizedBox(height: 14),
                        _InfoItem(LucideIcons.fileText, 'Observações', supplier.notes!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erro: $err', style: AppTheme.jakarta(color: AppColors.error))),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoItem(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 14, color: AppColors.accent),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTheme.jakarta(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
            const SizedBox(height: 2),
            Text(value, style: AppTheme.jakarta(fontSize: 13.5, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    ],
  );
}
