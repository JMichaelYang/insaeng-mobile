import 'package:alchemist/alchemist.dart';
import 'package:insaeng/design_system/atoms/app_button.dart';

import '../../helpers/golden.dart';

void main() {
  goldenVariantsTest(
    'AppButton',
    fileName: 'app_button',
    columns: 3,
    pumpBeforeTest: pumpNTimes(1, const Duration(milliseconds: 500)),
    variants: {
      for (final variant in AppButtonVariant.values) ...{
        variant.name: AppButton(label: 'Save', variant: variant, onPressed: () {}),
        '${variant.name} disabled': AppButton(label: 'Save', variant: variant, onPressed: null),
        '${variant.name} loading': AppButton(label: 'Save', variant: variant, isLoading: true, onPressed: () {}),
      },
    },
  );
}
