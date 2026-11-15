import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/generic_item_extensions.dart';
import 'package:insaeng/ui/generic/items/node_view.dart';
import 'package:material_ui/material_ui.dart';

class RowItem extends StatelessWidget {
  const new({required this.node, super.key});

  final RowNode node;

  @override
  Widget build(BuildContext context) {
    final spacing = context.watchBindable(node.spacing) ?? SpacingToken.none;
    final alignment = context.watchBindable(node.alignment) ?? AlignmentToken.start;
    final children = [for (final child in node.children) (child, context.watchFlex(child))];
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: spacing.size,
        crossAxisAlignment: alignment.crossAxis,
        children: [
          for (final (child, flex) in children)
            if (constraints.hasBoundedWidth && flex > 0)
              Expanded(
                key: ValueKey(('expanded', child.id)),
                flex: flex,
                child: NodeView(node: child),
              )
            else
              NodeView(node: child),
        ],
      ),
    );
  }
}
