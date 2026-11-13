part of '../generic_node.dart';

@MappableClass(discriminatorValue: 'appBar')
final class AppBarNode extends GenericNode with AppBarNodeMappable {
  const new({required super.id, this.title, this.leading = const Literal(AppBarLeadingToken.none)});

  @MappableField(hook: BindableHook<String>())
  final Bindable<String>? title;

  @MappableField(hook: BindableHook<AppBarLeadingToken>())
  final Bindable<AppBarLeadingToken> leading;
}
