part of '../generic_node.dart';

@MappableClass(discriminatorValue: 'textField')
final class TextFieldNode extends GenericNode with TextFieldNodeMappable {
  const new({
    required super.id,
    required this.bind,
    this.label,
    this.hint,
    this.onChanged = const [],
    this.onSubmit = const [],
  });

  final String bind;

  @MappableField(hook: BindableHook<String>())
  final Bindable<String>? label;

  @MappableField(hook: BindableHook<String>())
  final Bindable<String>? hint;

  final List<GenericAction> onChanged;

  final List<GenericAction> onSubmit;

  @override
  List<GenericAction> get actions => [...onChanged, ...onSubmit];
}
