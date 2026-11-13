import 'package:insaeng/design_system/theme/theme_extensions.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/generic_item_extensions.dart';
import 'package:material_ui/material_ui.dart';

class TextItem extends StatelessWidget {
  const new({required this.node, super.key});

  final TextNode node;

  @override
  Widget build(BuildContext context) {
    final text = context.watchBindable(node.text) ?? '';
    final style = context.watchBindable(node.style) ?? TextStyleToken.bodyMedium;
    return Text(text, style: style.resolve(context.textTheme));
  }
}
