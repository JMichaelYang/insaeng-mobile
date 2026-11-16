import 'package:insaeng/design_system/atoms/app_progress_bar.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/golden.dart';

void main() {
  goldenVariantsTest(
    'AppProgressBar',
    fileName: 'app_progress_bar',
    columns: 3,
    constraints: const BoxConstraints.tightFor(width: 240),
    variants: {
      'empty': const AppProgressBar(value: 0),
      'partial': const AppProgressBar(value: 0.4),
      'full': const AppProgressBar(value: 1),
    },
  );
}
