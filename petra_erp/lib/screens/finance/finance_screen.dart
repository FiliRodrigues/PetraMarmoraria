import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/finance/register_expense_dialog.dart';
import '../../widgets/finance/supplier_form_dialog.dart';
import 'tabs/receivables_tab.dart';
import 'tabs/suppliers_tab.dart';
import 'tabs/expenses_tab.dart';
import 'tabs/cash_flow_tab.dart';

/// Tela Financeira — refatorada com TabBar de 4 abas:
/// Recebíveis, Fornecedores, Despesas e Fluxo de Caixa.
class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshAll() {
    ref.read(paymentProvider.notifier).loadAll();
    ref.read(supplierProvider.notifier).loadAll();
    ref.read(expenseProvider.notifier).loadAll();
    final now = DateTime.now();
    ref.read(cashFlowProvider.notifier).load(DateTime(now.year, now.month));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financeiro'),
        actions: [
          // Botão Nova Conta
          IconButton(
            icon: const Icon(LucideIcons.plusCircle, size: 18),
            tooltip: 'Nova Conta',
            onPressed: () {
              RegisterExpenseDialog.show(context);
            },
          ),
          // Botão Novo Fornecedor
          IconButton(
            icon: const Icon(LucideIcons.userPlus, size: 18),
            tooltip: 'Novo Fornecedor',
            onPressed: () {
              SupplierFormDialog.show(context);
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: 'Atualizar',
            onPressed: _refreshAll,
          ),
        ],
      ),
      body: Column(
        children: [
          // TabBar
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              labelStyle: AppTheme.jakarta(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: AppTheme.jakarta(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
              ),
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  icon: Icon(LucideIcons.wallet, size: 18),
                  text: 'Recebíveis',
                ),
                Tab(
                  icon: Icon(LucideIcons.truck, size: 18),
                  text: 'Fornecedores',
                ),
                Tab(
                  icon: Icon(LucideIcons.receipt, size: 18),
                  text: 'Despesas',
                ),
                Tab(
                  icon: Icon(LucideIcons.barChart3, size: 18),
                  text: 'Fluxo de Caixa',
                ),
              ],
            ),
          ),
          // Conteúdo das abas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                ReceivablesTab(),
                SuppliersTab(),
                ExpensesTab(),
                CashFlowTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
