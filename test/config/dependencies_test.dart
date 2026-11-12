import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/config/dependencies.dart';
import 'package:insaeng/config/flavor.dart';

void main() {
  group(configureDependencies, () {
    tearDown(getIt.reset);

    for (final flavor in Flavor.values) {
      test('registers ${flavor.name} as the flavor', () {
        configureDependencies(flavor);

        expect(getIt<Flavor>(), flavor);
      });
    }
  });
}
