part of '../generic_node.dart';

@MappableEnum(defaultValue: IconButtonIcon.refresh)
enum IconButtonIcon { refresh }

@MappableClass(discriminatorValue: 'iconButton')
final class IconButtonNode extends GenericNode with IconButtonNodeMappable {
  const new({required super.id, required this.icon, this.label, this.onTap = const []});

  @MappableField(hook: BindableHook<IconButtonIcon>())
  final Bindable<IconButtonIcon> icon;

  @MappableField(hook: BindableHook<String>())
  final Bindable<String>? label;

  final List<GenericAction> onTap;

  @override
  List<GenericAction> get actions => onTap;
}
