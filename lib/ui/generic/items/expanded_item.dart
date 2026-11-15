import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/node_view.dart';
import 'package:material_ui/material_ui.dart';

class ExpandedItem extends StatelessWidget {
  const new({required this.node, super.key});

  final ExpandedNode node;

  @override
  Widget build(BuildContext context) => switch (node.child) {
    final child? => NodeView(node: child),
    null => const SizedBox.shrink(),
  };
}
