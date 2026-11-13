import 'package:insaeng/design_system/organisms/app_error_view.dart';

import '../../helpers/golden.dart';

void main() {
  goldenVariantsTest(
    'AppErrorView',
    fileName: 'app_error_view',
    variants: {
      'default': AppErrorView(
        message: 'Something went wrong loading this page.',
        retryLabel: 'Try again',
        onRetry: () {},
      ),
      'retry disabled': const AppErrorView(
        message: 'Something went wrong loading this page.',
        retryLabel: 'Try again',
        onRetry: null,
      ),
    },
  );
}
