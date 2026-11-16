import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/app_bar_item.dart';
import 'package:insaeng/ui/generic/items/button_item.dart';
import 'package:insaeng/ui/generic/items/checkbox_tile_item.dart';
import 'package:insaeng/ui/generic/items/column_item.dart';
import 'package:insaeng/ui/generic/items/container_item.dart';
import 'package:insaeng/ui/generic/items/divider_item.dart';
import 'package:insaeng/ui/generic/items/expanded_item.dart';
import 'package:insaeng/ui/generic/items/progress_bar_item.dart';
import 'package:insaeng/ui/generic/items/row_item.dart';
import 'package:insaeng/ui/generic/items/scroll_item.dart';
import 'package:insaeng/ui/generic/items/spacer_item.dart';
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
    final RowNode node => RowItem(node: node),
    final ContainerNode node => ContainerItem(node: node),
    final ScrollNode node => ScrollItem(node: node),
    final ExpandedNode node => ExpandedItem(node: node),
    final AppBarNode node => AppBarItem(node: node),
    final TextNode node => TextItem(node: node),
    final ButtonNode node => ButtonItem(node: node),
    final TextFieldNode node => TextFieldItem(node: node),
    final CheckboxTileNode node => CheckboxTileItem(node: node),
    final SpacerNode node => SpacerItem(node: node),
    final DividerNode node => DividerItem(node: node),
    final ProgressBarNode node => ProgressBarItem(node: node),
    final UnknownNode node => UnknownItem(node: node),
  };
}
