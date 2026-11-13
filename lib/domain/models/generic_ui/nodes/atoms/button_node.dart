part of '../generic_node.dart';

@MappableEnum(defaultValue: ButtonVariant.primary)
enum ButtonVariant { primary, secondary, text }

@MappableClass(discriminatorValue: 'button')
final class ButtonNode extends GenericNode with ButtonNodeMappable {
  const new({
    required super.id,
    required this.label,
    this.variant = const Literal(ButtonVariant.primary),
    this.loading = const Literal(false),
    this.onTap = const [],
  });

  @MappableField(hook: BindableHook<String>())
  final Bindable<String> label;

  @MappableField(hook: BindableHook<ButtonVariant>())
  final Bindable<ButtonVariant> variant;

  @MappableField(hook: BindableHook<bool>())
  final Bindable<bool> loading;

  final List<GenericAction> onTap;
}
