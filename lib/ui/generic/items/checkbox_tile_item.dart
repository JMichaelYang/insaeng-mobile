import 'package:insaeng/design_system/molecules/app_checkbox_tile.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/generic_item_extensions.dart';
import 'package:material_ui/material_ui.dart';

class CheckboxTileItem extends StatelessWidget {
  const new({required this.node, super.key});

  final CheckboxTileNode node;

  @override
  Widget build(BuildContext context) {
    final mark = context.watchBindable(node.mark) ?? CheckboxMark.check;
    return AppCheckboxTile(
      title: context.watchBindable(node.title) ?? '',
      subtitle: context.watchBindable(node.subtitle),
      emoji: context.watchBindable(node.emoji),
      checked: context.watchBindable(Binding<bool>(node.bind)) ?? false,
      busy: context.watchBindable(node.busy) ?? false,
      mark: switch (mark) {
        CheckboxMark.check => AppCheckboxMark.check,
        CheckboxMark.dash => AppCheckboxMark.dash,
      },
      onChanged: (checked) =>
          context.dispatch([UpdateStateAction(path: node.bind, value: Literal(checked)), ...node.onChanged]),
    );
  }
}
