import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/generic_item_extensions.dart';
import 'package:insaeng/ui/generic/items/node_view.dart';
import 'package:material_ui/material_ui.dart';

class ContainerItem extends StatelessWidget {
  const new({required this.node, super.key});

  final ContainerNode node;

  @override
  Widget build(BuildContext context) {
    final padding = context.watchBindable(node.padding) ?? SpacingToken.none;
    final alignment = context.watchBindable(node.alignment) ?? AlignmentToken.start;
    return Container(
      padding: EdgeInsets.all(padding.size),
      alignment: alignment.horizontal,
      width: alignment == AlignmentToken.stretch ? double.infinity : null,
      child: switch (node.child) {
        final child? => NodeView(node: child),
        null => null,
      },
    );
  }
}
