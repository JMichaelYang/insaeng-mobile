import 'package:insaeng/ui/core/theme/colors.dart';
import 'package:material_ui/material_ui.dart';

/// Material 3 themes built from the app's color tokens.
abstract final class AppTheme {
  static final ThemeData light = _build(Brightness.light);
  static final ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
    );
    return ThemeData(colorScheme: colorScheme);
  }
}
