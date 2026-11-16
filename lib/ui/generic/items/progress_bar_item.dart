import 'package:insaeng/design_system/atoms/app_progress_bar.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/generic_item_extensions.dart';
import 'package:material_ui/material_ui.dart';

class ProgressBarItem extends StatelessWidget {
  const new({required this.node, super.key});

  final ProgressBarNode node;

  @override
  Widget build(BuildContext context) {
    final value = context.watchBindable(node.value) ?? 0;
    final max = context.watchBindable(node.max) ?? 0;
    return AppProgressBar(value: max > 0 ? value / max : 0);
  }
}
