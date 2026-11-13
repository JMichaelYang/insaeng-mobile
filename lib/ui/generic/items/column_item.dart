import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/generic_item_extensions.dart';
import 'package:insaeng/ui/generic/items/node_view.dart';
import 'package:material_ui/material_ui.dart';

class ColumnItem extends StatelessWidget {
  const new({required this.node, super.key});

  final ColumnNode node;

  @override
  Widget build(BuildContext context) {
    final spacing = context.watchBindable(node.spacing) ?? SpacingToken.none;
    final alignment = context.watchBindable(node.alignment) ?? AlignmentToken.start;
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: spacing.size,
      crossAxisAlignment: alignment.crossAxis,
      children: [for (final child in node.children) NodeView(node: child)],
    );
  }
}
