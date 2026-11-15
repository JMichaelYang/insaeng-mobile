part of '../generic_node.dart';

@MappableClass(discriminatorValue: 'textField')
final class TextFieldNode extends GenericNode with TextFieldNodeMappable {
  const new({
    required super.id,
    required this.bind,
    this.label,
    this.hint,
    this.secure = const Literal(false),
    this.onChanged = const [],
    this.onSubmit = const [],
  });

  final String bind;

  @MappableField(hook: BindableHook<String>())
  final Bindable<String>? label;

  @MappableField(hook: BindableHook<String>())
  final Bindable<String>? hint;

  @MappableField(hook: BindableHook<bool>())
  final Bindable<bool> secure;

  final List<GenericAction> onChanged;

  final List<GenericAction> onSubmit;

  @override
  List<GenericAction> get actions => [...onChanged, ...onSubmit];
}
