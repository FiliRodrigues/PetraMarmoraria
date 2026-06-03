import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/os_status.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/os_provider.dart';
import '../../providers/employee_provider.dart';

/// Modal dialog to confirm status changes, collect notes, and enforce employee
/// assignments when entering cutting, assembly, or delivery stages.
class StatusTransitionDialog extends ConsumerStatefulWidget {
  final ServiceOrder order;
  final String?
  targetStatus; // If drag-dropped, target is known. Otherwise, select.
  final VoidCallback? onTransitionCompleted;

  const StatusTransitionDialog({
    super.key,
    required this.order,
    this.targetStatus,
    this.onTransitionCompleted,
  });

  @override
  ConsumerState<StatusTransitionDialog> createState() =>
      _StatusTransitionDialogState();
}

class _StatusTransitionDialogState
    extends ConsumerState<StatusTransitionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  String? _selectedStatus;
  String? _selectedEmployeeId;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Use targetStatus if provided, otherwise default to the next logical status
    _selectedStatus = widget.targetStatus ?? OSStatus.next(widget.order.status);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  List<String> _getAvailableTransitions() {
    final current = widget.order.status;
    final list = <String>[];

    final next = OSStatus.next(current);
    if (next != null) list.add(next);

    final prev = OSStatus.previous(current);
    if (prev != null) list.add(prev);

    return list;
  }

  List<ServiceOrder> _olderBehind(
    ServiceOrder moving,
    String newStatus,
    List<ServiceOrder> allOrders,
  ) {
    final nextStatusIndex = OSStatus.indexOf(newStatus);
    if (nextStatusIndex < 0) return const [];

    final olderBehind = allOrders.where((order) {
      if (order.id == moving.id) return false;
      if (order.queuePosition >= moving.queuePosition) return false;
      if (order.status == OSStatus.orcamento ||
          order.status == OSStatus.entregue) {
        return false;
      }

      final olderStatusIndex = OSStatus.indexOf(order.status);
      if (olderStatusIndex < 0) return false;

      return nextStatusIndex > olderStatusIndex;
    }).toList()..sort((a, b) => a.queuePosition.compareTo(b.queuePosition));

    return olderBehind;
  }

  Future<bool> _confirmQueueBypass(
    List<ServiceOrder> olderBehind,
    String newStatus,
  ) async {
    final impacted = olderBehind.take(2).toList();
    final statusLabel = OSStatus.labels[newStatus] ?? newStatus;
    final impactedLines = impacted
        .map(
          (order) =>
              '- OS ${order.formattedNumber} (${order.statusLabel}), cadastrada antes, ainda está atrás.',
        )
        .join('\n');
    final extraCount = olderBehind.length - impacted.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Passar na frente?',
          style: AppTheme.syne(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A movimentação da OS ${widget.order.formattedNumber} para $statusLabel vai ultrapassar ordem de fila.',
              style: AppTheme.jakarta(fontSize: 13),
            ),
            const SizedBox(height: 10),
            Text(
              impactedLines,
              style: AppTheme.jakarta(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            if (extraCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '+$extraCount OS mais antiga(s) também serão ultrapassadas.',
                style: AppTheme.jakarta(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Deseja realmente avançar?',
              style: AppTheme.jakarta(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancelar',
              style: AppTheme.jakarta(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Sim, avançar',
              style: AppTheme.jakarta(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    return confirmed == true;
  }

  Future<void> _submitTransition() async {
    if (_selectedStatus == null) return;

    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      return;
    }

    final currentUser = ref.read(authProvider).value;
    if (currentUser == null) {
      setState(() {
        _errorMessage = 'Usuário não autenticado no sistema.';
      });
      return;
    }

    final allOrders =
        ref.read(osProvider).valueOrNull ?? const <ServiceOrder>[];
    final olderBehind = _olderBehind(widget.order, _selectedStatus!, allOrders);
    if (olderBehind.isNotEmpty) {
      final confirmed = await _confirmQueueBypass(
        olderBehind,
        _selectedStatus!,
      );
      if (!confirmed) return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(osProvider.notifier)
          .moveOrder(
            orderId: widget.order.id,
            newStatus: _selectedStatus!,
            changedById: currentUser.id,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            employeeId: _selectedEmployeeId,
          );

      if (widget.onTransitionCompleted != null) {
        widget.onTransitionCompleted!();
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
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
    final currentStatusLabel =
        OSStatus.labels[widget.order.status] ?? widget.order.status;
    final availableTransitions = _getAvailableTransitions();

    if (widget.targetStatus == null && availableTransitions.isEmpty) {
      return AlertDialog(
        title: Text(
          'Nenhuma etapa disponível',
          style: AppTheme.syne(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'A OS ${widget.order.formattedNumber} está em "$currentStatusLabel" '
          'e não há etapas seguintes ou anteriores para mover.',
          style: AppTheme.jakarta(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Fechar',
              style: AppTheme.jakarta(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    }

    final requiresAssignment =
        _selectedStatus != null &&
        OSStatus.requiresAssignment(_selectedStatus!);
    final requiredRole = _selectedStatus != null
        ? OSStatus.requiredRole(_selectedStatus!)
        : null;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.swap_horiz, color: AppColors.secondary),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              'Alterar Etapa: OS ${widget.order.formattedNumber}',
              style: AppTheme.syne(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Etapa Atual: $currentStatusLabel',
                style: AppTheme.jakarta(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16.0),

              // Destination Status selection
              Text(
                'Nova Etapa',
                style: AppTheme.jakarta(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey,
                ),
              ),
              const SizedBox(height: 6.0),
              if (widget.targetStatus != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 12.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: AppColors.lightGrey),
                  ),
                  child: Text(
                    OSStatus.labels[widget.targetStatus] ??
                        widget.targetStatus!,
                    style: AppTheme.jakarta(fontWeight: FontWeight.w700),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                  ),
                  items: availableTransitions.map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(OSStatus.labels[status] ?? status),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedStatus = val;
                      _selectedEmployeeId =
                          null; // Reset employee selection on stage change
                    });
                  },
                ),
              const SizedBox(height: 16.0),

              // Employee Selection if stage requires assignment
              if (requiresAssignment && requiredRole != null) ...[
                Text(
                  'Responsável pela Etapa (${requiredRole.toUpperCase()})',
                  style: AppTheme.jakarta(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey,
                  ),
                ),
                const SizedBox(height: 6.0),
                ref
                    .watch(activeEmployeesByRoleProvider(requiredRole))
                    .when(
                      data: (employees) {
                        if (employees.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Atenção: Nenhum funcionário com cargo "$requiredRole" ativo cadastrado.',
                              style: AppTheme.jakarta(
                                color: AppColors.error,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        }
                        return DropdownButtonFormField<String>(
                          initialValue: _selectedEmployeeId,
                          hint: const Text('Selecione o funcionário'),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 8.0,
                            ),
                          ),
                          items: employees.map((emp) {
                            return DropdownMenuItem<String>(
                              value: emp.id,
                              child: Text(emp.name),
                            );
                          }).toList(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Selecione um funcionário';
                            }
                            return null;
                          },
                          onChanged: (val) {
                            setState(() {
                              _selectedEmployeeId = val;
                            });
                          },
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (err, _) => Text(
                        'Erro ao carregar funcionários: $err',
                        style: AppTheme.jakarta(color: AppColors.error),
                      ),
                    ),
                const SizedBox(height: 16.0),
              ],

              // Notes Input Field
              Text(
                'Observações (Opcional)',
                style: AppTheme.jakarta(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey,
                ),
              ),
              const SizedBox(height: 6.0),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Adicione detalhes sobre a mudança de etapa...',
                  contentPadding: EdgeInsets.all(12.0),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16.0),
                Text(
                  _errorMessage!,
                  style: AppTheme.jakarta(color: AppColors.error, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: Text(
            'Cancelar',
            style: AppTheme.jakarta(
              color: AppColors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading || _selectedStatus == null
              ? null
              : _submitTransition,
          child: _isLoading
              ? const SizedBox(
                  width: 18.0,
                  height: 18.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Confirmar',
                  style: AppTheme.jakarta(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ],
    );
  }
}
