import 'package:insaeng/design_system/atoms/app_button.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/generic_item_extensions.dart';
import 'package:material_ui/material_ui.dart';

class ButtonItem extends StatelessWidget {
  const new({required this.node, super.key});

  final ButtonNode node;

  @override
  Widget build(BuildContext context) {
    final variant = context.watchBindable(node.variant) ?? ButtonVariant.primary;
    return AppButton(
      label: context.watchBindable(node.label) ?? '',
      isLoading: context.watchBindable(node.loading) ?? false,
      variant: switch (variant) {
        ButtonVariant.primary => AppButtonVariant.primary,
        ButtonVariant.secondary => AppButtonVariant.secondary,
        ButtonVariant.text => AppButtonVariant.text,
      },
      onPressed: () => context.dispatch(node.onTap),
    );
  }
}
