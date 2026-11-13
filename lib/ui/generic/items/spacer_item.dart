import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:material_ui/material_ui.dart';

class SpacerItem extends StatelessWidget {
  const new({required this.node, super.key});

  final SpacerNode node;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
