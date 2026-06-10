import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/error_messages.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../pdf/pdf.dart';
import 'os_detail_screen.dart';

class OSPrintData {
  final ServiceOrder order;
  final Customer? customer;
  final List<OrderAssignment> assignments;
  final List<StatusHistory> history;
  final List<Profile> profiles;
  final CompanyInfo? company;
  final Uint8List? drawingBytes;
  final bool drawingIsPdf;

  OSPrintData({
    required this.order,
    this.customer,
    this.assignments = const [],
    this.history = const [],
    this.profiles = const [],
    this.company,
    this.drawingBytes,
    this.drawingIsPdf = false,
  });
}

// Faz APENAS o download do anexo do desenho (rede assíncrona, não toca no UI
// isolate). Cacheado por URL — usado tanto no pré-download em background quanto
// na geração do PDF, sem rebaixar.
final drawingBytesProvider =
    FutureProvider.family<({Uint8List? bytes, bool isPdf}), String>((ref, url) async {
  if (url.trim().isEmpty) return (bytes: null, isPdf: false);
  try {
    final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
    if (resp.statusCode == 200) {
      return (bytes: resp.bodyBytes, isPdf: url.toLowerCase().endsWith('.pdf'));
    }
  } catch (e) { debugPrint('[OSPrint] Erro desenho: $e'); }
  return (bytes: null, isPdf: false);
});

final osPrintDataProvider = FutureProvider.family<OSPrintData, String>((ref, id) async {
  final companyService = ref.watch(companyServiceProvider);

  // Reusa os dados já carregados (e cacheados) pela tela de detalhe — evita
  // rebuscar order/customer/assignments/history/profiles do Supabase.
  final detail = await ref.watch(osDetailDataProvider(id).future);
  final order = detail.order;

  // Só o que o detail não tem: dados da empresa + download do desenho, em paralelo.
  // O desenho reusa o cache do drawingBytesProvider (pré-baixado em background).
  final companyFuture =
      companyService.getCompanyInfo().then<CompanyInfo?>((c) => c).catchError((_) => null);
  final drawingFuture = ref.watch(drawingBytesProvider(order.drawingUrl ?? '').future);

  final results = await Future.wait([companyFuture, drawingFuture]);
  final company = results[0] as CompanyInfo?;
  final drawing = results[1] as ({Uint8List? bytes, bool isPdf});

  return OSPrintData(
    order: order, customer: detail.customer, assignments: detail.assignments,
    history: detail.history, profiles: detail.profiles, company: company,
    drawingBytes: drawing.bytes, drawingIsPdf: drawing.isPdf,
  );
});

final printModeProvider = StateProvider<String>((ref) => 'admin');

// PDF is generated per (id, mode) — no re-fetch on mode switch, just regeneration
final generatedPdfProvider = FutureProvider.family<Uint8List, ({String id, String mode})>((ref, args) async {
  final data = await ref.watch(osPrintDataProvider(args.id).future);

  debugPrint('[PrintScreen] Gerando PDF para OS ${data.order.formattedNumber}, modo=${args.mode}');

  return await generateServiceOrderPdfIsolate(
    order: data.order,
    customer: data.customer,
    assignments: data.assignments,
    history: data.history,
    profiles: data.profiles,
    company: data.company,
    drawingBytes: data.drawingBytes,
    drawingIsPdf: data.drawingIsPdf,
    printMode: args.mode,
  );
});

class OSPrintScreen extends ConsumerWidget {
  final String id;
  const OSPrintScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final printMode = ref.watch(printModeProvider);
    final pdfArgs = (id: id, mode: printMode);
    final pdfAsync = ref.watch(generatedPdfProvider(pdfArgs));
    final printDataAsync = ref.watch(osPrintDataProvider(id));

    final displayNumber = printDataAsync.maybeWhen(
      data: (d) => d.order.displayNumber.toString().padLeft(4, '0'),
      orElse: () => '0000',
    );
    final isProduction = printMode == 'producao';
    final fileName = 'OS_$displayNumber${isProduction ? "_producao" : ""}.pdf';

    return Scaffold(
      appBar: AppBar(title: const Text('Imprimir OS')),
      body: Column(
        children: [
          _ModeToggle(printMode: printMode, ref: ref),
          Expanded(
            child: pdfAsync.when(
              data: (pdfBytes) {
                debugPrint('[PrintScreen] PDF pronto, ${pdfBytes.length} bytes');
                return PdfPreview(
                  build: (format) async => pdfBytes,
                  allowSharing: true,
                  allowPrinting: true,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  initialPageFormat: PdfPageFormat.a4,
                  pdfFileName: fileName,
                );
              },
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Gerando PDF...'),
                  ],
                ),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 60),
                      const SizedBox(height: 16),
                      Text(friendlyError(err), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(generatedPdfProvider(pdfArgs)),
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final String printMode;
  final WidgetRef ref;

  const _ModeToggle({required this.printMode, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ModeChip(
            label: 'Administrativo',
            isSelected: printMode == 'admin',
            onTap: () => ref.read(printModeProvider.notifier).state = 'admin',
          ),
          const SizedBox(width: 8),
          _ModeChip(
            label: 'Produção',
            isSelected: printMode == 'producao',
            onTap: () => ref.read(printModeProvider.notifier).state = 'producao',
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = isSelected
        ? AppColors.accent.withValues(alpha: 0.17)
        : Colors.transparent;
    final fg = isSelected
        ? AppColors.accent
        : Colors.white.withValues(alpha: 0.7);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: isSelected ? AppColors.accent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.jakarta(
            fontSize: 13.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: fg,
          ),
        ),
      ),
    );
  }
}
