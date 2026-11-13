import 'package:dart_mappable/dart_mappable.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';

part 'generic_node.mapper.dart';

@MappableEnum(defaultValue: TextStyleToken.bodyMedium)
enum TextStyleToken {
  displayLarge,
  displayMedium,
  displaySmall,
  headlineLarge,
  headlineMedium,
  headlineSmall,
  titleLarge,
  titleMedium,
  titleSmall,
  bodyLarge,
  bodyMedium,
  bodySmall,
  labelLarge,
  labelMedium,
  labelSmall,
}

@MappableEnum(defaultValue: SpacingToken.none)
enum SpacingToken { none, xs, sm, md, lg, xl }

@MappableEnum(defaultValue: AlignmentToken.start)
enum AlignmentToken { start, center, end, stretch }

@MappableEnum(defaultValue: ButtonVariantToken.primary)
enum ButtonVariantToken { primary, secondary, text }

@MappableEnum(defaultValue: AppBarLeadingToken.none)
enum AppBarLeadingToken { none, back, close }

@MappableClass(discriminatorKey: 'type')
sealed class GenericNode with GenericNodeMappable {
  const new({required this.id});

  final String id;
}

@MappableClass(discriminatorValue: 'column')
final class ColumnNode extends GenericNode with ColumnNodeMappable {
  const new({
    required super.id,
    this.children = const [],
    this.spacing = const Literal(SpacingToken.none),
    this.alignment = const Literal(AlignmentToken.start),
  });

  final List<GenericNode> children;

  @MappableField(hook: BindableHook<SpacingToken>())
  final Bindable<SpacingToken> spacing;

  @MappableField(hook: BindableHook<AlignmentToken>())
  final Bindable<AlignmentToken> alignment;
}

@MappableClass(discriminatorValue: 'appBar')
final class AppBarNode extends GenericNode with AppBarNodeMappable {
  const new({required super.id, this.title, this.leading = const Literal(AppBarLeadingToken.none)});

  @MappableField(hook: BindableHook<String>())
  final Bindable<String>? title;

  @MappableField(hook: BindableHook<AppBarLeadingToken>())
  final Bindable<AppBarLeadingToken> leading;
}

@MappableClass(discriminatorValue: 'text')
final class TextNode extends GenericNode with TextNodeMappable {
  const new({required super.id, required this.text, this.style = const Literal(TextStyleToken.bodyMedium)});

  @MappableField(hook: BindableHook<String>())
  final Bindable<String> text;

  @MappableField(hook: BindableHook<TextStyleToken>())
  final Bindable<TextStyleToken> style;
}

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

@MappableClass(discriminatorValue: MappableClass.useAsDefault)
final class UnknownNode extends GenericNode with UnknownNodeMappable {
  const new({required super.id, this.fallback});

  final GenericNode? fallback;
}
