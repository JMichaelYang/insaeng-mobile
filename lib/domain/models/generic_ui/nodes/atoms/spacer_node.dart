part of '../generic_node.dart';

@MappableClass(discriminatorValue: 'spacer')
final class SpacerNode extends GenericNode with SpacerNodeMappable {
  const new({required super.id, this.size = const Literal(SpacingToken.md)});

  @MappableField(hook: BindableHook<SpacingToken>())
  final Bindable<SpacingToken> size;
}
