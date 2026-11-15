import 'package:insaeng/design_system/atoms/app_text_field.dart';

import '../../helpers/golden.dart';

void main() {
  goldenVariantsTest(
    'AppTextField',
    fileName: 'app_text_field',
    columns: 2,
    variants: {
      'empty': const AppTextField(),
      'label': const AppTextField(label: 'Name', hint: 'Enter your name'),
      'filled': const AppTextField(label: 'Name', value: 'Ada Lovelace'),
      'hint': const AppTextField(hint: 'Enter your name'),
    },
  );
}
