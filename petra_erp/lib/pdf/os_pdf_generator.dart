import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

Future<Uint8List?> fetchNetworkImage(String url) async {
  try {
    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
  } catch (_) {
  }
  return null;
}

/// Generates a highly professional A4 PDF document for the given [order].
/// Standard Helvetica font is used throughout the layout.
/// Margins are set to 40px (points).
Future<Uint8List> generateServiceOrderPdf({
  required ServiceOrder order,
  Customer? customer,
  List<OrderAssignment> assignments = const [],
  List<StatusHistory> history = const [],
  List<Profile> profiles = const [],
  CompanyInfo? company,
  Uint8List? drawingBytes,
  bool drawingIsPdf = false,
  String printMode = 'admin',
}) async {
  final pdf = pw.Document();

  debugPrint('[PDF] Iniciando geração PDF, printMode=$printMode, hasDrawing=${drawingBytes != null}');

  // Typography (Helvetica)
  final fontRegular = pw.Font.helvetica();
  final fontBold = pw.Font.helveticaBold();

  // Branding colors
  final primaryColor = PdfColor.fromInt(0xFF1A1A1A);       // Charcoal/Black
  final secondaryColor = PdfColor.fromInt(0xFFC4A747);     // Warm Gold Accent
  final greyColor = PdfColor.fromInt(0xFF666666);          // Text grey
  final lightGreyColor = PdfColor.fromInt(0xFFE0E0E0);     // Border grey
  final backgroundCreme = PdfColor.fromInt(0xFFF5F0E8);    // Surface/Header background

  // Text Styles
  final titleStyle = pw.TextStyle(font: fontBold, fontSize: 18, color: primaryColor);
  final subtitleStyle = pw.TextStyle(font: fontRegular, fontSize: 10, color: greyColor);
  final osNumberStyle = pw.TextStyle(font: fontBold, fontSize: 18, color: secondaryColor);
  final sectionHeaderStyle = pw.TextStyle(font: fontBold, fontSize: 12, color: primaryColor);
  final labelStyle = pw.TextStyle(font: fontBold, fontSize: 9, color: primaryColor);
  final valueStyle = pw.TextStyle(font: fontRegular, fontSize: 9, color: primaryColor);
  final footerLabelStyle = pw.TextStyle(font: fontBold, fontSize: 10, color: primaryColor);
  final footerValueStyle = pw.TextStyle(font: fontBold, fontSize: 14, color: secondaryColor);

  // Attempt to load network image if drawingUrl is provided
  pw.MemoryImage? drawingImage;
  if (drawingBytes != null) {
    debugPrint('[PDF] Processando bytes do desenho, isPdf=$drawingIsPdf');
    if (drawingIsPdf) {
      try {
        final rastered = Printing.raster(drawingBytes, pages: [0], dpi: 150);
        final rasterList = await rastered.toList();
        debugPrint('[PDF] Rasterização concluída, páginas=${rasterList.length}');
        if (rasterList.isNotEmpty) {
          final png = await rasterList.first.toPng();
          drawingImage = pw.MemoryImage(png);
          debugPrint('[PDF] PNG gerado, ${png.length} bytes');
        }
      } catch (e) {
        debugPrint('[PDF] Erro na rasterização: $e');
      }
    } else {
      drawingImage = pw.MemoryImage(drawingBytes);
      debugPrint('[PDF] Imagem direta, ${drawingBytes.length} bytes');
    }
  } else if (order.drawingUrl != null && order.drawingUrl!.trim().isNotEmpty) {
    debugPrint('[PDF] Baixando desenho da URL: ${order.drawingUrl}');
    final bytes = await fetchNetworkImage(order.drawingUrl!);
    if (bytes != null) {
      drawingImage = pw.MemoryImage(bytes);
      debugPrint('[PDF] Download concluído, ${bytes.length} bytes');
    } else {
      debugPrint('[PDF] AVISO: não foi possível baixar o desenho de ${order.drawingUrl} — PDF será gerado sem o desenho.');
    }
  }

  // Parse measurements
  final List<Map<String, String>> measurementRows = [];
  final measurements = order.measurements;
  if (measurements.containsKey('items') && measurements['items'] is List) {
    final list = measurements['items'] as List;
    for (final item in list) {
      if (item is Map) {
        measurementRows.add({
          'width': (item['width'] ?? item['largura'] ?? '-').toString(),
          'height': (item['height'] ?? item['altura'] ?? '-').toString(),
          'thickness': (item['thickness'] ?? item['espessura'] ?? '-').toString(),
          'format': (item['format'] ?? item['formato'] ?? '-').toString(),
          'details': (item['details'] ?? item['detalhes'] ?? '-').toString(),
        });
      }
    }
  } else {
    final hasKeys = measurements.containsKey('width') ||
        measurements.containsKey('largura') ||
        measurements.containsKey('height') ||
        measurements.containsKey('altura') ||
        measurements.containsKey('thickness') ||
        measurements.containsKey('espessura');
    if (hasKeys) {
      measurementRows.add({
        'width': (measurements['width'] ?? measurements['largura'] ?? '-').toString(),
        'height': (measurements['height'] ?? measurements['altura'] ?? '-').toString(),
        'thickness': (measurements['thickness'] ?? measurements['espessura'] ?? '-').toString(),
        'format': (measurements['format'] ?? measurements['formato'] ?? '-').toString(),
        'details': (measurements['details'] ?? measurements['detalhes'] ?? '-').toString(),
      });
    }
  }

  // Resolve assigned team members
  String vendedor = 'Não atribuído';
  String cortador = 'Não atribuído';
  String montador = 'Não atribuído';
  String entregador = 'Não atribuído';

  for (final assignment in assignments) {
    final name = assignment.employeeName ?? 'Atribuído';
    if (assignment.stage == 'corte') {
      cortador = name;
    } else if (assignment.stage == 'montagem') {
      montador = name;
    } else if (assignment.stage == 'entrega') {
      entregador = name;
    }
  }

  // Vendedor responsável: prioriza created_by (novo campo); cai na heurística
  // antiga (histórico/perfil) apenas para OS legadas.
  if (order.createdByName != null && order.createdByName!.isNotEmpty) {
    vendedor = order.createdByName!;
  } else if (order.createdBy != null) {
    final creator = profiles.firstWhere(
      (p) => p.id == order.createdBy,
      orElse: () => Profile(id: '', email: '', name: '', createdAt: DateTime(1970)),
    );
    if (creator.name.isNotEmpty) vendedor = creator.name;
  }

  // Try to find the vendedor from status history or profiles
  if (vendedor == 'Não atribuído' && history.isNotEmpty) {
    final sortedHistory = List<StatusHistory>.from(history)
      ..sort((a, b) => a.changedAt.compareTo(b.changedAt));
    final firstEntry = sortedHistory.first;
    final creatorProfile = profiles.firstWhere(
      (p) => p.id == firstEntry.changedBy,
      orElse: () => Profile(
        id: '',
        email: '',
        name: '',
        createdAt: DateTime(1970),
      ),
    );
    if (creatorProfile.name.isNotEmpty && creatorProfile.role.toLowerCase() == 'vendedor') {
      vendedor = creatorProfile.name;
    } else if (firstEntry.changedByName != null) {
      vendedor = firstEntry.changedByName!;
    }
  }

  if (vendedor == 'Não atribuído') {
    final sellerProfile = profiles.firstWhere(
      (p) => p.role.toLowerCase() == 'vendedor',
      orElse: () => Profile(
        id: '',
        email: '',
        name: '',
        createdAt: DateTime(1970),
      ),
    );
    if (sellerProfile.name.isNotEmpty) {
      vendedor = sellerProfile.name;
    }
  }

  // Formatters
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final dateOnlyFormat = DateFormat('dd/MM/yyyy');
  final currencyFormat = NumberFormat.simpleCurrency(locale: 'pt_BR');

  // Build the PDF Document layout
  final isProduction = printMode == 'producao';
  debugPrint('[PDF] Construindo layout, isProduction=$isProduction');
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.copyWith(
        marginLeft: 40,
        marginTop: 40,
        marginRight: 40,
        marginBottom: 40,
      ),
      theme: pw.ThemeData.withFont(
        base: fontRegular,
        bold: fontBold,
      ),
      header: (pw.Context context) {
        return pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      (company?.name.isNotEmpty ?? false)
                          ? company!.name.toUpperCase()
                          : 'PETRA MARMORARIA',
                      style: titleStyle,
                    ),
                    pw.Text(
                      [company?.address, company?.phone, company?.cnpj != null ? 'CNPJ: ${company!.cnpj}' : null]
                              .where((e) => e != null && e.isNotEmpty)
                              .join('  •  ')
                              .isNotEmpty
                          ? [company?.address, company?.phone, company?.cnpj != null ? 'CNPJ: ${company!.cnpj}' : null]
                              .where((e) => e != null && e.isNotEmpty)
                              .join('  •  ')
                          : 'Mármores, Granitos e Pedras Decorativas',
                      style: subtitleStyle,
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('ORDEM DE SERVIÇO ${order.formattedNumber}', style: osNumberStyle),
                    pw.Text('Data: ${dateOnlyFormat.format(order.createdAt)}', style: subtitleStyle),
                  ],
                ),
              ],
            ),
            pw.Container(
              height: 2,
              color: secondaryColor,
              margin: const pw.EdgeInsets.only(top: 8, bottom: 15),
            ),
          ],
        );
      },
      footer: (pw.Context context) {
        final isProductionFooter = printMode == 'producao';
        return pw.Column(
          children: [
            pw.Container(
              height: 1,
              color: lightGreyColor,
              margin: const pw.EdgeInsets.only(top: 15, bottom: 8),
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                if (isProductionFooter)
                  pw.SizedBox(width: 0)
                else
                  pw.Text(
                    'Petra ERP - Documento gerado em ${dateFormat.format(DateTime.now())}',
                    style: pw.TextStyle(font: fontRegular, fontSize: 7, color: greyColor),
                  ),
                pw.Text(
                  'Página ${context.pageNumber} de ${context.pagesCount}',
                  style: pw.TextStyle(font: fontRegular, fontSize: 7, color: greyColor),
                ),
              ],
            ),
          ],
        );
      },
      build: (pw.Context context) {
        return [
          // Section 1: Customer Details
          pw.Text('DADOS DO CLIENTE', style: sectionHeaderStyle),
          pw.SizedBox(height: 4),
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: lightGreyColor, width: 1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            padding: const pw.EdgeInsets.all(10),
            margin: const pw.EdgeInsets.only(bottom: 15),
            child: pw.Column(
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: pw.Row(
                        children: [
                          pw.Text('Nome: ', style: labelStyle),
                          pw.Expanded(
                            child: pw.Text(
                              customer?.name ?? order.customerName ?? 'Não informado',
                              style: valueStyle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isProduction)
                      pw.Expanded(
                        flex: 1,
                        child: pw.Row(
                          children: [
                            pw.Text('Telefone: ', style: labelStyle),
                            pw.Text(customer?.phone ?? '-', style: valueStyle),
                          ],
                        ),
                      ),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Row(
                        children: [
                          pw.Text('Endereço: ', style: labelStyle),
                          pw.Expanded(
                            child: pw.Text(
                              customer?.address ?? 'Não informado',
                              style: valueStyle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!isProduction && (customer?.city != null || customer?.state != null)) ...[
                  pw.SizedBox(height: 6),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Row(
                          children: [
                            pw.Text('Cidade/UF: ', style: labelStyle),
                            pw.Text(
                              '${customer?.city ?? "-"} / ${customer?.state ?? "-"}',
                              style: valueStyle,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Section 2: Specifications (Material and Edge type)
          pw.Text('ESPECIFICAÇÕES DO SERVIÇO', style: sectionHeaderStyle),
          pw.SizedBox(height: 4),
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: lightGreyColor, width: 1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            padding: const pw.EdgeInsets.all(10),
            margin: const pw.EdgeInsets.only(bottom: 15),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Row(
                        children: [
                          pw.Text('Material: ', style: labelStyle),
                          pw.Text(order.material ?? 'Não informado', style: valueStyle),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Row(
                        children: [
                          pw.Text('Tipo de Acabamento: ', style: labelStyle),
                          pw.Text(order.edgeType ?? 'Não informado', style: valueStyle),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!isProduction) ...[
                  pw.SizedBox(height: 6),
                  pw.Text('Descrição / Observações:', style: labelStyle),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    order.description.isNotEmpty ? order.description : 'Nenhuma observação informada.',
                    style: valueStyle,
                  ),
                ],
              ],
            ),
          ),

          // Section 3: Measurements Table
          pw.Text('MEDIÇÕES', style: sectionHeaderStyle),
          pw.SizedBox(height: 4),
          pw.Table(
            border: pw.TableBorder.all(color: lightGreyColor, width: 1),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: backgroundCreme),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Largura (m)', style: labelStyle),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Altura (m)', style: labelStyle),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Espessura (cm)', style: labelStyle),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Formato', style: labelStyle),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Detalhes', style: labelStyle),
                  ),
                ],
              ),
              if (measurementRows.isEmpty)
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Nenhuma medição registrada', style: valueStyle),
                    ),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('-')),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('-')),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('-')),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('-')),
                  ],
                )
              else
                ...measurementRows.map(
                  (row) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(row['width'] ?? '-', style: valueStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(row['height'] ?? '-', style: valueStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(row['thickness'] ?? '-', style: valueStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(row['format'] ?? '-', style: valueStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(row['details'] ?? '-', style: valueStyle),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          pw.SizedBox(height: 15),

          // Section 4: Drawing/Sketch
          pw.Text('DESENHO / ESBOÇO', style: sectionHeaderStyle),
          pw.SizedBox(height: 4),
          if (drawingImage != null)
            pw.Container(
              height: 180,
              width: double.infinity,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: lightGreyColor, width: 1),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              padding: const pw.EdgeInsets.all(5),
              alignment: pw.Alignment.center,
              child: pw.Image(drawingImage, fit: pw.BoxFit.contain),
            )
          else
            pw.Container(
              height: 120,
              width: double.infinity,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: lightGreyColor,
                  style: pw.BorderStyle.dashed,
                  width: 1.5,
                ),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'Nenhum desenho ou esboço anexado a esta Ordem de Serviço.',
                style: pw.TextStyle(font: fontRegular, fontSize: 9, color: greyColor),
              ),
            ),
          pw.SizedBox(height: 15),

          // Section 5: Assigned Team (admin only)
          if (!isProduction) ...[
            pw.Text('EQUIPE RESPONSÁVEL', style: sectionHeaderStyle),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: lightGreyColor, width: 1),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: backgroundCreme),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Função', style: labelStyle),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Responsável', style: labelStyle),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Vendedor', style: labelStyle),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(vendedor, style: valueStyle),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Cortador', style: labelStyle),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(cortador, style: valueStyle),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Montador', style: labelStyle),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(montador, style: valueStyle),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Entregador / Instalador', style: labelStyle),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(entregador, style: valueStyle),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
          ],

          // Section 6: Footer values / totals (admin only)
          if (!isProduction)
            pw.Container(
              decoration: pw.BoxDecoration(
                color: backgroundCreme,
                border: pw.Border.all(color: secondaryColor, width: 1),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              padding: const pw.EdgeInsets.all(12),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('STATUS DA OS', style: footerLabelStyle),
                      pw.SizedBox(height: 2),
                      pw.Text(order.statusLabel.toUpperCase(), style: titleStyle.copyWith(fontSize: 14)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('VALOR TOTAL', style: footerLabelStyle),
                      pw.SizedBox(height: 2),
                      pw.Text(currencyFormat.format(order.totalValue), style: footerValueStyle),
                    ],
                  ),
                ],
              ),
            ),
        ];
      },
    ),
  );

  if (drawingImage != null) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginLeft: 20,
          marginTop: 20,
          marginRight: 20,
          marginBottom: 20,
        ),
        build: (pw.Context context) {
          final img = drawingImage!;
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                'DESENHO / CROQUI — OS ${order.formattedNumber}',
                style: titleStyle,
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 10),
              pw.Expanded(
                child: pw.Center(
                  child: pw.Image(img, fit: pw.BoxFit.contain),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  debugPrint('[PDF] Salvando PDF...');
  final result = await pdf.save();
  debugPrint('[PDF] PDF gerado com sucesso, ${result.length} bytes');
  return result;
}
