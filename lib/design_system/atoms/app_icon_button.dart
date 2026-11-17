import 'package:insaeng/design_system/theme/dimens.dart';
import 'package:insaeng/design_system/theme/theme_extensions.dart';
import 'package:material_ui/material_ui.dart';

class AppIconButton extends StatelessWidget {
  const new({required this.icon, required this.label, required this.onPressed, this.isLoading = false, super.key});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final color = context.colorScheme.primary;
    return IconButton(
      onPressed: isLoading ? null : onPressed,
      color: color,
      disabledColor: isLoading ? color : null,
      icon: Semantics(label: label, child: isLoading ? const _AppIconButtonSpinner() : Icon(icon)),
    );
  }
}

class _AppIconButtonSpinner extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    return SizedBox.square(
      dimension: iconTheme.size,
      child: Padding(
        padding: const EdgeInsets.all(Dimens.strokeSm),
        child: CircularProgressIndicator(strokeWidth: Dimens.strokeSm, color: iconTheme.color),
      ),
    );
  }
}
