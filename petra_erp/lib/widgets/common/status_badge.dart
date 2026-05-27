import 'package:flutter/material.dart';
import '../../core/constants/os_status.dart';

/// A custom badge to display the stage status with a corresponding color indicator.
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case OSStatus.orcamento:
        return Colors.blueGrey.shade700;
      case OSStatus.aprovado:
        return Colors.blue.shade700;
      case OSStatus.recebido:
        return Colors.teal.shade700;
      case OSStatus.esperandoMaterial:
        return Colors.orange.shade800;
      case OSStatus.corte:
        return Colors.purple.shade700;
      case OSStatus.montagem:
        return Colors.indigo.shade700;
      case OSStatus.entrega:
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = OSStatus.labels[status] ?? status;
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11.0,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
