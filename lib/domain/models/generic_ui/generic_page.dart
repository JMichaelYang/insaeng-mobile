import 'package:dart_mappable/dart_mappable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';

part 'generic_page.mapper.dart';

@MappableClass()
final class GenericPage with GenericPageMappable {
  const new({required this.id, required this.root, this.state, this.onLoad = const []});

  final String id;

  final GenericNode root;

  @MappableField(hook: GenericValuesHook())
  final GenericValues? state;

  final List<GenericAction> onLoad;

  GenericValues get initialState => state ?? GenericValues.empty;
}
