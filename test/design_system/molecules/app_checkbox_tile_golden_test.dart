import 'package:alchemist/alchemist.dart';
import 'package:insaeng/design_system/molecules/app_checkbox_tile.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/golden.dart';

void main() {
  goldenVariantsTest(
    'AppCheckboxTile',
    fileName: 'app_checkbox_tile',
    columns: 2,
    constraints: const BoxConstraints.tightFor(width: 320),
    pumpBeforeTest: pumpNTimes(1, const Duration(milliseconds: 500)),
    variants: {
      for (final checked in [false, true]) ...{
        for (final subtitle in [null, '10 minutes'])
          '${checked ? 'checked' : 'unchecked'}${subtitle == null ? '' : ' with subtitle'}': AppCheckboxTile(
            title: 'Stretch',
            subtitle: subtitle,
            emoji: subtitle == null ? null : '🧘',
            checked: checked,
            onChanged: (_) {},
          ),
        '${checked ? 'checked' : 'unchecked'} busy': AppCheckboxTile(
          title: 'Stretch',
          subtitle: '10 minutes',
          emoji: '🧘',
          checked: checked,
          busy: true,
          onChanged: (_) {},
        ),
      },
      'cross checked': AppCheckboxTile(
        title: 'Stretch',
        subtitle: '10 minutes',
        emoji: '🧘',
        checked: true,
        mark: AppCheckboxMark.cross,
        onChanged: (_) {},
      ),
      'cross checked busy': AppCheckboxTile(
        title: 'Stretch',
        subtitle: '10 minutes',
        emoji: '🧘',
        checked: true,
        busy: true,
        mark: AppCheckboxMark.cross,
        onChanged: (_) {},
      ),
      'cross unchecked': AppCheckboxTile(
        title: 'Stretch',
        subtitle: '10 minutes',
        emoji: '🧘',
        checked: false,
        mark: AppCheckboxMark.cross,
        onChanged: (_) {},
      ),
    },
  );
}
