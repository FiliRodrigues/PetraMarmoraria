import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../pdf/os_pdf_generator.dart';

/// Exibe o desenho da OS (PDF ou imagem) em tela cheia com zoom/pan.
/// PDFs são rasterizados em PNG para visualização sem dependência de viewer.
class DrawingViewerScreen extends StatefulWidget {
  final String url;
  final String title;

  const DrawingViewerScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<DrawingViewerScreen> createState() => _DrawingViewerScreenState();
}

class _DrawingViewerScreenState extends State<DrawingViewerScreen> {
  late final Future<Uint8List?> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadImage();
  }

  Future<Uint8List?> _loadImage() async {
    final bytes = await fetchNetworkImage(widget.url);
    if (bytes == null) return null;

    if (widget.url.toLowerCase().endsWith('.pdf')) {
      final pages = await Printing.raster(bytes, pages: [0], dpi: 200).toList();
      if (pages.isEmpty) return null;
      return pages.first.toPng();
    }
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title),
      ),
      body: FutureBuilder<Uint8List?>(
        future: _imageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final bytes = snapshot.data;
          if (bytes == null) {
            return Center(
              child: Text(
                'Não foi possível carregar o desenho.',
                style: AppTheme.jakarta(color: AppColors.textSecondary),
              ),
            );
          }
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 5,
            child: Center(child: Image.memory(bytes)),
          );
        },
      ),
    );
  }
}
