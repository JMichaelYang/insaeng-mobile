import 'package:insaeng/design_system/theme/dimens.dart';
import 'package:material_ui/material_ui.dart';

class AppCheckboxTile extends StatelessWidget {
  const new({
    required this.title,
    required this.checked,
    required this.onChanged,
    this.subtitle,
    this.emoji,
    this.busy = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final String? emoji;
  final bool checked;
  final bool busy;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final onChanged = busy ? null : this.onChanged;
    final subtitle = this.subtitle;
    final emoji = this.emoji;
    return MergeSemantics(
      child: ListTile(
        enabled: onChanged != null,
        onTap: onChanged == null ? null : () => onChanged(!checked),
        leading: emoji == null ? null : Text(emoji, style: TextTheme.of(context).titleLarge),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: Dimens.spaceSm,
          children: [
            if (busy) const _AppCheckboxTileSpinner(),
            Checkbox(value: checked, onChanged: onChanged == null ? null : (value) => onChanged(value ?? false)),
          ],
        ),
      ),
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
