import 'package:insaeng/design_system/theme/dimens.dart';
import 'package:insaeng/design_system/theme/theme_extensions.dart';
import 'package:material_ui/material_ui.dart';

class AppProgressBar extends StatelessWidget {
  const new({required this.value, super.key});

  final double value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return LinearProgressIndicator(
      value: value.isFinite ? value.clamp(0, 1) : 0,
      minHeight: Dimens.progressHeight,
      borderRadius: BorderRadius.circular(Dimens.radiusFull),
      color: colors.primary,
      backgroundColor: colors.surfaceContainerHighest,
    );
  }
}
