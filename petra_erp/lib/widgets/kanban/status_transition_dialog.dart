import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
  final String? targetStatus; // If drag-dropped, target is known. Otherwise, select.
  final VoidCallback? onTransitionCompleted;

  const StatusTransitionDialog({
    super.key,
    required this.order,
    this.targetStatus,
    this.onTransitionCompleted,
  });

  @override
  ConsumerState<StatusTransitionDialog> createState() => _StatusTransitionDialogState();
}

class _StatusTransitionDialogState extends ConsumerState<StatusTransitionDialog> {
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

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(osProvider.notifier).moveOrder(
        orderId: widget.order.id,
        newStatus: _selectedStatus!,
        changedById: currentUser.id,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        employeeId: _selectedEmployeeId,
      );

      if (widget.onTransitionCompleted != null) {
        widget.onTransitionCompleted!();
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
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
    final currentStatusLabel = OSStatus.labels[widget.order.status] ?? widget.order.status;
    final availableTransitions = _getAvailableTransitions();
    final requiresAssignment = _selectedStatus != null && OSStatus.requiresAssignment(_selectedStatus!);
    final requiredRole = _selectedStatus != null ? OSStatus.requiredRole(_selectedStatus!) : null;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(LucideIcons.arrowLeftRight, size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Alterar Etapa: OS ${widget.order.formattedNumber}',
              style: AppTheme.syne(fontSize: 15, fontWeight: FontWeight.w700),
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
                style: AppTheme.jakarta(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),

              Text('Nova Etapa',
                style: AppTheme.jakarta(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              if (widget.targetStatus != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    OSStatus.labels[widget.targetStatus] ?? widget.targetStatus!,
                    style: AppTheme.jakarta(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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
                      _selectedEmployeeId = null; // Reset employee selection on stage change
                    });
                  },
                ),
              const SizedBox(height: 16.0),

              // Employee Selection if stage requires assignment
              if (requiresAssignment && requiredRole != null) ...[
                Text(
                  'Responsável pela Etapa (${requiredRole.toUpperCase()})',
                  style: AppTheme.jakarta(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                ),
                const SizedBox(height: 6),
                ref.watch(activeEmployeesByRoleProvider(requiredRole)).when(
                  data: (employees) {
                    if (employees.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Atenção: Nenhum funcionário com cargo "$requiredRole" ativo cadastrado.',
                          style: AppTheme.jakarta(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.error),
                        ),
                      );
                    }
                    return DropdownButtonFormField<String>(
                      value: _selectedEmployeeId,
                      hint: const Text('Selecione o funcionário'),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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
                  error: (err, _) => Text('Erro ao carregar funcionários: $err',
                    style: AppTheme.jakarta(color: AppColors.error)),
                ),
                const SizedBox(height: 16),
              ],

              Text('Observações (Opcional)',
                style: AppTheme.jakarta(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Adicione detalhes sobre a mudança de etapa...',
                  contentPadding: EdgeInsets.all(12.0),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                Text(_errorMessage!,
                  style: AppTheme.jakarta(fontSize: 13, color: AppColors.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: Text('Cancelar', style: AppTheme.jakarta(fontSize: 13, color: AppColors.textMuted)),
        ),
        ElevatedButton(
          onPressed: _isLoading || _selectedStatus == null ? null : _submitTransition,
          child: _isLoading
              ? const SizedBox(
                  width: 18.0,
                  height: 18.0,
                  child: CircularProgressIndicator(strokeWidth: 2.0, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                )
              : const Text('Confirmar'),
        ),
      ],
    );
  }
}
