part of '../generic_node.dart';

@MappableClass(discriminatorValue: 'container')
final class ContainerNode extends GenericNode with ContainerNodeMappable {
  const new({
    required super.id,
    this.child,
    this.padding = const Literal(SpacingToken.none),
    this.alignment = const Literal(AlignmentToken.start),
  });

  final GenericNode? child;

  @MappableField(hook: BindableHook<SpacingToken>())
  final Bindable<SpacingToken> padding;

  @MappableField(hook: BindableHook<AlignmentToken>())
  final Bindable<AlignmentToken> alignment;

  @override
  List<GenericNode> get childNodes => [?child];
}
