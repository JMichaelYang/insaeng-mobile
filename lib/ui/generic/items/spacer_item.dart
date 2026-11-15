import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/generic_item_extensions.dart';
import 'package:material_ui/material_ui.dart';

class SpacerItem extends StatelessWidget {
  const new({required this.node, super.key});

  final SpacerNode node;

  @override
  Widget build(BuildContext context) {
    final size = context.watchBindable(node.size) ?? SpacingToken.md;
    return SizedBox.square(dimension: size.size);
  }
}
