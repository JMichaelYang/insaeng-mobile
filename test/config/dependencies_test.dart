import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/config/dependencies.dart';
import 'package:insaeng/config/flavor.dart';
import 'package:insaeng/data/repositories/generic_page_repository_impl.dart';
import 'package:insaeng/domain/repositories/generic_page_repository.dart';

void main() {
  group(configureDependencies, () {
    tearDown(getIt.reset);

    for (final flavor in Flavor.values) {
      test('registers ${flavor.name} as the flavor', () {
        configureDependencies(flavor);

        expect(getIt<Flavor>(), flavor);
      });

      test('registers the fixture page repository for ${flavor.name}', () {
        configureDependencies(flavor);

        expect(getIt<GenericPageRepository>(), isA<GenericPageRepositoryImpl>());
      });
    }
  });
}
