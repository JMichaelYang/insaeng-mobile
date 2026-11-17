part of '../generic_node.dart';

@MappableClass(discriminatorValue: 'iconButton')
final class IconButtonNode extends GenericNode with IconButtonNodeMappable {
  const new({
    required super.id,
    required this.icon,
    required this.label,
    this.loading = const Literal(false),
    this.onTap = const [],
  });

  @MappableField(hook: BindableHook<IconToken>())
  final Bindable<IconToken> icon;

  @MappableField(hook: BindableHook<String>())
  final Bindable<String> label;

  @MappableField(hook: BindableHook<bool>())
  final Bindable<bool> loading;

  final List<GenericAction> onTap;

  @override
  List<GenericAction> get actions => onTap;
}
