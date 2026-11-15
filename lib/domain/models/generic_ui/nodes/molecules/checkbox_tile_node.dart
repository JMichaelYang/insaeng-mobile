part of '../generic_node.dart';

@MappableClass(discriminatorValue: 'checkboxTile')
final class CheckboxTileNode extends GenericNode with CheckboxTileNodeMappable {
  const new({
    required super.id,
    required this.bind,
    required this.title,
    this.subtitle,
    this.emoji,
    this.busy = const Literal(false),
    this.onChanged = const [],
  });

  final String bind;

  @MappableField(hook: BindableHook<String>())
  final Bindable<String> title;

  @MappableField(hook: BindableHook<String>())
  final Bindable<String>? subtitle;

  @MappableField(hook: BindableHook<String>())
  final Bindable<String>? emoji;

  @MappableField(hook: BindableHook<bool>())
  final Bindable<bool> busy;

  final List<GenericAction> onChanged;

  @override
  List<GenericAction> get actions => onChanged;
}
