import 'package:dart_mappable/dart_mappable.dart';
import 'package:insaeng/domain/models/home_widget/widget_tap.dart';

part 'widget_node.mapper.dart';

@MappableClass(ignoreNull: true)
final class WidgetNode with WidgetNodeMappable {
  const new({required this.type, required this.id, this.props = const {}, this.children = const [], this.tap});

  final String type;

  final String id;

  final Map<String, Object?> props;

  final List<WidgetNode> children;

  final WidgetTap? tap;
}
