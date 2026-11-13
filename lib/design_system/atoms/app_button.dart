import 'package:insaeng/design_system/theme/dimens.dart';
import 'package:material_ui/material_ui.dart';

enum AppButtonVariant { primary, secondary, text }

class AppButton extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final handler = isLoading ? null : onPressed;
    final child = _AppButtonContent(label: label, isLoading: isLoading);
    return switch (variant) {
      AppButtonVariant.primary => FilledButton(onPressed: handler, child: child),
      AppButtonVariant.secondary => OutlinedButton(onPressed: handler, child: child),
      AppButtonVariant.text => TextButton(onPressed: handler, child: child),
    };
  }
}

class _AppButtonContent extends StatelessWidget {
  const new({required this.label, required this.isLoading});

  final String label;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final text = Text(label);
    if (!isLoading) return text;
    final iconTheme = IconTheme.of(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        Visibility.maintain(visible: false, child: text),
        SizedBox.square(
          dimension: iconTheme.size,
          child: CircularProgressIndicator(strokeWidth: Dimens.strokeSm, color: iconTheme.color),
        ),
      ],
    );
  }
}
