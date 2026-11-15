import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/generic_item_extensions.dart';
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
      builder: (context, constraints) => switch ((constraints.hasBoundedHeight, node.onRefresh)) {
        (false, _) => child ?? const SizedBox.shrink(),
        (true, []) => SingleChildScrollView(child: child),
        (true, final onRefresh) => RefreshIndicator(
          onRefresh: () => context.dispatch(onRefresh),
          child: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), child: child),
        ),
      },
    );
  }
}
