import 'package:insaeng/design_system/molecules/app_day_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/golden.dart';

void main() {
  goldenVariantsTest(
    'AppDayPicker',
    fileName: 'app_day_picker',
    constraints: const BoxConstraints.tightFor(width: 320),
    variants: {
      'enabled': AppDayPicker(
        label: 'Mon, Jan 12',
        previousLabel: 'Previous day',
        nextLabel: 'Next day',
        onPrevious: () {},
        onNext: () {},
      ),
      'next disabled': AppDayPicker(
        label: 'Mon, Jan 12',
        previousLabel: 'Previous day',
        nextLabel: 'Next day',
        onPrevious: () {},
        onNext: null,
      ),
      'label tappable': AppDayPicker(
        label: 'Fri, Jan 16',
        previousLabel: 'Previous day',
        nextLabel: 'Next day',
        onPrevious: () {},
        onNext: () {},
        onLabelTap: () {},
        labelTapHint: 'Go to today',
      ),
      'long label': AppDayPicker(
        label: 'Wednesday, September 30, 2026',
        previousLabel: 'Previous day',
        nextLabel: 'Next day',
        onPrevious: () {},
        onNext: () {},
      ),
    },
  );
}
