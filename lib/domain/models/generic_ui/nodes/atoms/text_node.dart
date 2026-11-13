part of '../generic_node.dart';

@MappableClass(discriminatorValue: 'text')
final class TextNode extends GenericNode with TextNodeMappable {
  const new({required super.id, required this.text, this.style = const Literal(TextStyleToken.bodyMedium)});

  @MappableField(hook: BindableHook<String>())
  final Bindable<String> text;

  @MappableField(hook: BindableHook<TextStyleToken>())
  final Bindable<TextStyleToken> style;
}
