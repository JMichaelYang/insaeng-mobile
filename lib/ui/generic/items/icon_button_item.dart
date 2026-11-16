import 'package:insaeng/design_system/atoms/app_icon_button.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/generic_item_extensions.dart';
import 'package:material_ui/material_ui.dart';

class IconButtonItem extends StatelessWidget {
  const new({required this.node, super.key});

  final IconButtonNode node;

  @override
  Widget build(BuildContext context) {
    final icon = context.watchBindable(node.icon) ?? IconButtonIcon.refresh;
    return AppIconButton(
      icon: switch (icon) {
        IconButtonIcon.refresh => Icons.refresh,
      },
      tooltip: context.watchBindable(node.label),
      onPressed: () => context.dispatch(node.onTap),
    );
  }
}
