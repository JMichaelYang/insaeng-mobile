part of '../generic_node.dart';

@MappableClass(discriminatorValue: 'button')
final class ButtonNode extends GenericNode with ButtonNodeMappable {
  const new({
    required super.id,
    required this.label,
    this.variant = const Literal(ButtonVariantToken.primary),
    this.loading = const Literal(false),
    this.onTap = const [],
  });

  @MappableField(hook: BindableHook<String>())
  final Bindable<String> label;

  @MappableField(hook: BindableHook<ButtonVariantToken>())
  final Bindable<ButtonVariantToken> variant;

  @MappableField(hook: BindableHook<bool>())
  final Bindable<bool> loading;

  final List<GenericAction> onTap;
}
