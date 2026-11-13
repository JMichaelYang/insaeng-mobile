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

  Iterable<GenericNode> get nodes => _descendants(root);

  Iterable<GenericAction> get actions => [...onLoad, for (final node in nodes) ...node.actions];

  static Iterable<GenericNode> _descendants(GenericNode node) sync* {
    yield node;
    for (final child in node.childNodes) {
      yield* _descendants(child);
    }
  }
}
