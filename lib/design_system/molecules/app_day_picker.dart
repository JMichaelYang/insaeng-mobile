import 'package:insaeng/design_system/atoms/app_icon_button.dart';
import 'package:insaeng/design_system/theme/theme_extensions.dart';
import 'package:material_ui/material_ui.dart';

class AppDayPicker extends StatelessWidget {
  const new({
    required this.label,
    required this.previousLabel,
    required this.nextLabel,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final String label;
  final String previousLabel;
  final String nextLabel;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIconButton(icon: Icons.chevron_left, label: previousLabel, onPressed: onPrevious),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.titleMedium,
          ),
        ),
        AppIconButton(icon: Icons.chevron_right, label: nextLabel, onPressed: onNext),
      ],
    );
  }
}
