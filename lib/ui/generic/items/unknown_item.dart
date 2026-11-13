import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/node_view.dart';
import 'package:material_ui/material_ui.dart';

class UnknownItem extends StatelessWidget {
  const new({required this.node, super.key});

  final UnknownNode node;

  @override
  Widget build(BuildContext context) => switch (node.fallback) {
    final fallback? => NodeView(node: fallback),
    null => const SizedBox.shrink(),
  };
}
