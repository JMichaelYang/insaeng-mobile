import 'package:dart_mappable/dart_mappable.dart';

part 'node_tokens.mapper.dart';

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
