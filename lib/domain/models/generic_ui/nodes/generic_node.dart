import 'package:dart_mappable/dart_mappable.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/node_tokens.dart';

export 'package:insaeng/domain/models/generic_ui/nodes/node_tokens.dart';

part 'atoms/button_node.dart';
part 'atoms/text_node.dart';
part 'generic_node.mapper.dart';
part 'layout/column_node.dart';
part 'organisms/app_bar_node.dart';
part 'unknown_node.dart';

@MappableClass(discriminatorKey: 'type')
sealed class GenericNode with GenericNodeMappable {
  const new({required this.id});

  final String id;

  List<GenericNode> get childNodes => switch (this) {
    ColumnNode(:final children) => children,
    UnknownNode(:final fallback) => [?fallback],
    AppBarNode() || ButtonNode() || TextNode() => const [],
  };

  List<GenericAction> get actions => switch (this) {
    ButtonNode(:final onTap) => onTap,
    AppBarNode() || ColumnNode() || TextNode() || UnknownNode() => const [],
  };
}
