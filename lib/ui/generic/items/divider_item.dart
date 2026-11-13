import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:material_ui/material_ui.dart';

class DividerItem extends StatelessWidget {
  const new({required this.node, super.key});

  final DividerNode node;

  @override
  Widget build(BuildContext context) => const Divider();
}
