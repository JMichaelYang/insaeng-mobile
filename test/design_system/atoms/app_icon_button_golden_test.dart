import 'package:insaeng/design_system/atoms/app_icon_button.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/golden.dart';

void main() {
  goldenVariantsTest(
    'AppIconButton',
    fileName: 'app_icon_button',
    columns: 2,
    variants: {
      'enabled': AppIconButton(icon: Icons.refresh, onPressed: () {}),
      'disabled': const AppIconButton(icon: Icons.refresh, onPressed: null),
    },
  );
}
