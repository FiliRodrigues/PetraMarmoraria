import 'package:flutter/material.dart';
import '../../core/utils/responsive.dart';

/// Dispõe cards de KPI lado a lado no desktop/tablet e em grade 2×2 no celular.
///
/// Os [children] devem ser widgets que já se expandem (ex.: retornam `Expanded`),
/// pois são colocados dentro de uma `Row` que fornece a largura limitada.
class ResponsiveKpiGrid extends StatelessWidget {
  final List<Widget> children;
  final double gap;

  const ResponsiveKpiGrid({super.key, required this.children, this.gap = 12});

  @override
  Widget build(BuildContext context) {
    if (!context.isMobile) {
      return Row(children: _withGaps(children));
    }

    // Celular: pares em linhas de 2 (2×2 para 4 KPIs).
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      final pair = <Widget>[children[i]];
      if (i + 1 < children.length) {
        pair.add(SizedBox(width: gap));
        pair.add(children[i + 1]);
      } else {
        // Ímpar: ocupa metade para não esticar sozinho na linha.
        pair.add(SizedBox(width: gap));
        pair.add(const Expanded(child: SizedBox.shrink()));
      }
      if (rows.isNotEmpty) rows.add(SizedBox(height: gap));
      rows.add(IntrinsicHeight(child: Row(children: pair)));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }

  List<Widget> _withGaps(List<Widget> items) {
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) out.add(SizedBox(width: gap));
      out.add(items[i]);
    }
    return out;
  }
}
