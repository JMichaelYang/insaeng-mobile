import 'package:insaeng/design_system/theme/dimens.dart';
import 'package:material_ui/material_ui.dart';

enum AppCheckboxMark { check, dash }

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
    final dashed = checked && mark == AppCheckboxMark.dash;
    final checkbox = Checkbox(
      value: dashed ? null : checked,
      tristate: dashed,
      onChanged: onChanged == null ? null : (_) => onChanged(!checked),
    );
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
            if (dashed) _AppCheckboxTileDash(enabled: onChanged != null, child: checkbox) else checkbox,
          ],
        ),
      ),
    );
  }
}

class _AppCheckboxTileDash extends StatelessWidget {
  const new({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return Semantics(
      checked: true,
      enabled: enabled,
      child: ExcludeSemantics(
        child: CheckboxTheme(
          data: CheckboxTheme.of(context).copyWith(
            fillColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled) ? null : colorScheme.error,
            ),
            checkColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled) ? null : colorScheme.onError,
            ),
          ),
          child: child,
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
