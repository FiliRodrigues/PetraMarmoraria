import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../pdf/pdf.dart';

/// Container class to hold all data needed to render the Service Order PDF.
class OSPrintData {
  final ServiceOrder order;
  final Customer? customer;
  final List<OrderAssignment> assignments;
  final List<StatusHistory> history;
  final List<Profile> profiles;

  OSPrintData({
    required this.order,
    this.customer,
    this.assignments = const [],
    this.history = const [],
    this.profiles = const [],
  });
}

/// Provider that loads all necessary details for printing in parallel.
final osPrintDataProvider = FutureProvider.family<OSPrintData, String>((ref, id) async {
  final serviceOrderService = ref.watch(serviceOrderServiceProvider);
  final customerService = ref.watch(customerServiceProvider);
  final profileService = ref.watch(profileServiceProvider);

  // 1. Fetch OS details
  final order = await serviceOrderService.getServiceOrderById(id);

  // 2. Fetch Customer details (if customerId exists)
  Customer? customer;
  try {
    customer = await customerService.getCustomerById(order.customerId);
  } catch (_) {
    // Fail silently if customer details fail to load; the PDF generator handles it
  }

  // 3. Fetch Assignments
  List<OrderAssignment> assignments = [];
  try {
    assignments = await serviceOrderService.getAssignments(id);
  } catch (_) {}

  // 4. Fetch Status History
  List<StatusHistory> history = [];
  try {
    history = await serviceOrderService.getStatusHistory(id);
  } catch (_) {}

  // 5. Fetch Profiles
  List<Profile> profiles = [];
  try {
    profiles = await profileService.getProfiles();
  } catch (_) {}

  return OSPrintData(
    order: order,
    customer: customer,
    assignments: assignments,
    history: history,
    profiles: profiles,
  );
});

class OSPrintScreen extends ConsumerWidget {
  final String id;
  const OSPrintScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final printDataAsync = ref.watch(osPrintDataProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Imprimir OS'),
      ),
      body: printDataAsync.when(
        data: (data) {
          final fileName = 'OS_${data.order.displayNumber.toString().padLeft(4, '0')}.pdf';
          return PdfPreview(
            build: (format) => generateServiceOrderPdf(
              order: data.order,
              customer: data.customer,
              assignments: data.assignments,
              history: data.history,
              profiles: data.profiles,
            ),
            allowSharing: true,
            allowPrinting: true,
            canChangePageFormat: false,
            canChangeOrientation: false,
            initialPageFormat: PdfPageFormat.a4,
            pdfFileName: fileName,
            loadingWidget: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Gerando PDF...', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Carregando dados para impressão...', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                Text(
                  'Erro ao carregar dados da OS:\n$err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(osPrintDataProvider(id)),
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
