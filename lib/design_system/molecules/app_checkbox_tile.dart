import 'package:insaeng/design_system/theme/dimens.dart';
import 'package:material_ui/material_ui.dart';

class AppCheckboxTile extends StatelessWidget {
  const new({
    required this.title,
    required this.checked,
    required this.onChanged,
    this.subtitle,
    this.busy = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final bool checked;
  final bool busy;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    final subtitle = this.subtitle;
    return CheckboxListTile(
      value: checked,
      onChanged: busy || onChanged == null ? null : (value) => onChanged(value ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      secondary: busy ? const _AppCheckboxTileSpinner() : null,
    );
  }
}

class _AppCheckboxTileSpinner extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    return SizedBox.square(
      dimension: iconTheme.size,
      child: CircularProgressIndicator(strokeWidth: Dimens.strokeSm, color: iconTheme.color),
    );
  }
}
