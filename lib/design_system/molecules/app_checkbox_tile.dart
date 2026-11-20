import 'package:insaeng/design_system/theme/dimens.dart';
import 'package:material_ui/material_ui.dart';

enum AppCheckboxMark { check, cross }

class AppCheckboxTile extends StatelessWidget {
  const new({
    required this.title,
    required this.checked,
    required this.onChanged,
    this.subtitle,
    this.emoji,
    this.busy = false,
    this.mark = AppCheckboxMark.check,
    super.key,
  });

  final String title;
  final String? subtitle;
  final String? emoji;
  final bool checked;
  final bool busy;
  final AppCheckboxMark mark;
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
            _AppCheckboxTileBox(
              checked: checked,
              mark: mark,
              onPressed: onChanged == null ? null : () => onChanged(!checked),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppCheckboxTileBox extends StatelessWidget {
  const new({required this.checked, required this.mark, required this.onPressed});

  final bool checked;
  final AppCheckboxMark mark;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final (icon, color) = switch ((checked, mark)) {
      (false, _) => (Icons.check_box_outline_blank, colorScheme.onSurfaceVariant),
      (true, AppCheckboxMark.check) => (Icons.check_box, colorScheme.primary),
      (true, AppCheckboxMark.cross) => (Icons.disabled_by_default, colorScheme.error),
    };
    return Semantics(
      checked: checked,
      enabled: onPressed != null,
      child: ExcludeSemantics(
        child: IconButton(onPressed: onPressed, color: color, icon: Icon(icon)),
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
