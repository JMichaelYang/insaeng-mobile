import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/app_bar_item.dart';
import 'package:insaeng/ui/generic/items/button_item.dart';
import 'package:insaeng/ui/generic/items/column_item.dart';
import 'package:insaeng/ui/generic/items/container_item.dart';
import 'package:insaeng/ui/generic/items/divider_item.dart';
import 'package:insaeng/ui/generic/items/row_item.dart';
import 'package:insaeng/ui/generic/items/scroll_item.dart';
import 'package:insaeng/ui/generic/items/spacer_item.dart';
import 'package:insaeng/ui/generic/items/text_item.dart';
import 'package:insaeng/ui/generic/items/unknown_item.dart';
import 'package:material_ui/material_ui.dart';

class NodeView extends StatelessWidget {
  new({required this.node, this.expanded = false}) : super(key: ValueKey(node.id));

  final GenericNode node;

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final item = switch (node) {
      final ColumnNode node => ColumnItem(node: node),
      final RowNode node => RowItem(node: node),
      final ContainerNode node => ContainerItem(node: node),
      final ScrollNode node => ScrollItem(node: node),
      final AppBarNode node => AppBarItem(node: node),
      final TextNode node => TextItem(node: node),
      final ButtonNode node => ButtonItem(node: node),
      final SpacerNode node => SpacerItem(node: node),
      final DividerNode node => DividerItem(node: node),
      final UnknownNode node => UnknownItem(node: node),
    };
    return expanded ? Expanded(child: item) : item;
  }
}
