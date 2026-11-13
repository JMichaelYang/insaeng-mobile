import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/app_bar_item.dart';
import 'package:insaeng/ui/generic/items/button_item.dart';
import 'package:insaeng/ui/generic/items/column_item.dart';
import 'package:insaeng/ui/generic/items/text_field_item.dart';
import 'package:insaeng/ui/generic/items/text_item.dart';
import 'package:insaeng/ui/generic/items/unknown_item.dart';
import 'package:material_ui/material_ui.dart';

class NodeView extends StatelessWidget {
  new({required this.node}) : super(key: ValueKey(node.id));

  final GenericNode node;

  @override
  Widget build(BuildContext context) => switch (node) {
    final ColumnNode node => ColumnItem(node: node),
    final AppBarNode node => AppBarItem(node: node),
    final TextNode node => TextItem(node: node),
    final ButtonNode node => ButtonItem(node: node),
    final TextFieldNode node => TextFieldItem(node: node),
    final UnknownNode node => UnknownItem(node: node),
  };
}
