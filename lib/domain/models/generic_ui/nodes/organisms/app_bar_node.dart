part of '../generic_node.dart';

@MappableEnum(defaultValue: AppBarLeading.none)
enum AppBarLeading { none, back, close }

@MappableClass(discriminatorValue: 'appBar')
final class AppBarNode extends GenericNode with AppBarNodeMappable {
  const new({required super.id, this.title, this.leading = const Literal(AppBarLeading.none)});

  @MappableField(hook: BindableHook<String>())
  final Bindable<String>? title;

  @MappableField(hook: BindableHook<AppBarLeading>())
  final Bindable<AppBarLeading> leading;
}
