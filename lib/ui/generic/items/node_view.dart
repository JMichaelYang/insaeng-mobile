import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/app_bar_item.dart';
import 'package:insaeng/ui/generic/items/button_item.dart';
import 'package:insaeng/ui/generic/items/column_item.dart';
import 'package:insaeng/ui/generic/items/text_item.dart';
import 'package:insaeng/ui/generic/items/unknown_item.dart';
import 'package:material_ui/material_ui.dart';

class NodeView extends StatelessWidget {
  const new({required this.node, super.key});

  final GenericNode node;

  @override
  Widget build(BuildContext context) {
    final key = ValueKey(node.id);
    return switch (node) {
      final ColumnNode node => ColumnItem(key: key, node: node),
      final AppBarNode node => AppBarItem(key: key, node: node),
      final TextNode node => TextItem(key: key, node: node),
      final ButtonNode node => ButtonItem(key: key, node: node),
      final UnknownNode node => UnknownItem(key: key, node: node),
    };
  }
}
