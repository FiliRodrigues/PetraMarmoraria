import 'package:flutter/material.dart';
import '../../core/utils/responsive.dart';

/// Dispõe campos de formulário lado a lado no desktop/tablet e empilhados no celular.
///
/// [children] são os campos (sem `Expanded` em volta — o widget aplica).
/// [flex] opcional define a proporção de cada campo no desktop (mesmo length de
/// [children]); se nulo, todos recebem flex 1.
/// [trailing] é um widget de largura fixa que fica no fim da linha no desktop e
/// numa última linha alinhada à direita no celular (ex.: botão excluir/anexar).
class AdaptiveFieldRow extends StatelessWidget {
  final List<Widget> children;
  final List<int>? flex;
  final double gap;
  final Widget? trailing;

  const AdaptiveFieldRow({
    super.key,
    required this.children,
    this.flex,
    this.gap = 16,
    this.trailing,
  }) : assert(flex == null || flex.length == children.length);

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      final items = <Widget>[];
      for (var i = 0; i < children.length; i++) {
        if (i > 0) items.add(SizedBox(height: gap));
        items.add(children[i]);
      }
      if (trailing != null) {
        items.add(SizedBox(height: gap));
        items.add(Align(alignment: Alignment.centerRight, child: trailing!));
      }
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: items);
    }

    final row = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) row.add(SizedBox(width: gap));
      row.add(Expanded(flex: flex?[i] ?? 1, child: children[i]));
    }
    if (trailing != null) {
      row.add(SizedBox(width: gap));
      row.add(trailing!);
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: row);
  }
}
