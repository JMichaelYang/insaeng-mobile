import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/node_view.dart';
import 'package:material_ui/material_ui.dart';

class ScrollItem extends StatelessWidget {
  const new({required this.node, super.key});

  final ScrollNode node;

  @override
  Widget build(BuildContext context) {
    final child = switch (node.child) {
      final child? => NodeView(node: child),
      null => null,
    };
    return LayoutBuilder(
      builder: (context, constraints) =>
          constraints.hasBoundedHeight ? SingleChildScrollView(child: child) : child ?? const SizedBox.shrink(),
    );
  }
}
