part of '../generic_node.dart';

@MappableClass(discriminatorValue: 'column')
final class ColumnNode extends GenericNode with ColumnNodeMappable {
  const new({
    required super.id,
    this.children = const [],
    this.spacing = const Literal(SpacingToken.none),
    this.alignment = const Literal(AlignmentToken.start),
  });

  final List<GenericNode> children;

  @MappableField(hook: BindableHook<SpacingToken>())
  final Bindable<SpacingToken> spacing;

  @MappableField(hook: BindableHook<AlignmentToken>())
  final Bindable<AlignmentToken> alignment;

  @override
  List<GenericNode> get childNodes => children;
}
