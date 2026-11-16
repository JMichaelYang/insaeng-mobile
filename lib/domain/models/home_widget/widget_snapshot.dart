import 'package:dart_mappable/dart_mappable.dart';
import 'package:insaeng/domain/models/home_widget/widget_node.dart';

export 'package:insaeng/domain/models/home_widget/widget_node.dart';
export 'package:insaeng/domain/models/home_widget/widget_tap.dart';

part 'widget_snapshot.mapper.dart';

@MappableClass()
final class WidgetSnapshot with WidgetSnapshotMappable {
  const new({required this.pageId, required this.root});

  final String pageId;

  final WidgetNode root;
}
