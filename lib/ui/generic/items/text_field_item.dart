import 'package:insaeng/design_system/atoms/app_text_field.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/generic_item_extensions.dart';
import 'package:material_ui/material_ui.dart';

class TextFieldItem extends StatelessWidget {
  const new({required this.node, super.key});

  final TextFieldNode node;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      value: context.watchBindable(Binding<String>(node.bind)) ?? '',
      label: context.watchBindable(node.label),
      hint: context.watchBindable(node.hint),
      secure: context.watchBindable(node.secure) ?? false,
      onChanged: (text) =>
          context.dispatch([UpdateStateAction(path: node.bind, value: Literal(text)), ...node.onChanged]),
      onSubmitted: (_) => context.dispatch(node.onSubmit),
    );
  }
}
