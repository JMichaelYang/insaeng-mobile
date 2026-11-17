import 'package:alchemist/alchemist.dart';
import 'package:insaeng/design_system/atoms/app_icon_button.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/golden.dart';

void main() {
  goldenVariantsTest(
    'AppIconButton',
    fileName: 'app_icon_button',
    columns: 3,
    pumpBeforeTest: pumpNTimes(1, const Duration(milliseconds: 500)),
    variants: {
      'enabled': AppIconButton(icon: Icons.edit, label: 'Edit', onPressed: () {}),
      'disabled': const AppIconButton(icon: Icons.edit, label: 'Edit', onPressed: null),
      'loading': AppIconButton(icon: Icons.edit, label: 'Edit', isLoading: true, onPressed: () {}),
    },
  );
}
