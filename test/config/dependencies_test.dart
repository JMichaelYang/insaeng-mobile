import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/config/dependencies.dart';
import 'package:insaeng/config/flavor.dart';
import 'package:insaeng/data/repositories/generic_action_repository_impl.dart';
import 'package:insaeng/data/repositories/generic_page_repository_impl.dart';
import 'package:insaeng/data/services/secure_storage_service.dart';
import 'package:insaeng/domain/repositories/generic_action_repository.dart';
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

      test('registers the secure storage service for ${flavor.name}', () {
        configureDependencies(flavor);

        expect(getIt<SecureStorageService>(), isA<SecureStorageService>());
      });

      test('registers the action repository for ${flavor.name}', () {
        configureDependencies(flavor);

        expect(getIt<GenericActionRepository>(), isA<GenericActionRepositoryImpl>());
      });
    }
  });
}
