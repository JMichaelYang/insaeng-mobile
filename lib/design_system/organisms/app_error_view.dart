import 'package:insaeng/design_system/atoms/app_button.dart';
import 'package:insaeng/design_system/theme/dimens.dart';
import 'package:insaeng/design_system/theme/theme_extensions.dart';
import 'package:material_ui/material_ui.dart';

class AppErrorView extends StatelessWidget {
  const new({required this.message, required this.retryLabel, required this.onRetry, super.key});

  final String message;
  final String retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Dimens.spaceLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: Dimens.spaceMd,
        children: [
          Text(message, style: context.textTheme.bodyLarge, textAlign: TextAlign.center),
          AppButton(label: retryLabel, onPressed: onRetry),
        ],
      ),
    );
  }
}
