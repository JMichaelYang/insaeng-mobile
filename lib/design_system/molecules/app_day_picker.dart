import 'package:insaeng/design_system/atoms/app_icon_button.dart';
import 'package:insaeng/design_system/theme/dimens.dart';
import 'package:insaeng/design_system/theme/theme_extensions.dart';
import 'package:material_ui/material_ui.dart';

class AppDayPicker extends StatelessWidget {
  const new({
    required this.label,
    required this.previousLabel,
    required this.nextLabel,
    required this.onPrevious,
    required this.onNext,
    this.onLabelTap,
    this.labelTapHint,
    super.key,
  });

  final String label;
  final String previousLabel;
  final String nextLabel;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onLabelTap;
  final String? labelTapHint;

  @override
  Widget build(BuildContext context) {
    final onLabelTap = this.onLabelTap;
    final style = context.textTheme.titleMedium;
    final text = Text(
      label,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: onLabelTap == null ? style : style?.copyWith(color: context.colorScheme.primary),
    );
    return Row(
      children: [
        AppIconButton(icon: Icons.chevron_left, label: previousLabel, onPressed: onPrevious),
        Expanded(
          child: onLabelTap == null
              ? text
              : Semantics(
                  button: true,
                  hint: labelTapHint,
                  child: InkWell(
                    onTap: onLabelTap,
                    borderRadius: BorderRadius.circular(Dimens.radiusFull),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: Dimens.spaceSm),
                      child: text,
                    ),
                  ),
                ),
        ),
        AppIconButton(icon: Icons.chevron_right, label: nextLabel, onPressed: onNext),
      ],
    );
  }
}
