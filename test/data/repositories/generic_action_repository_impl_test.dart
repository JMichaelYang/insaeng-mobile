import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/data/repositories/generic_action_repository_impl.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/repositories/generic_action_repository.dart';
import 'package:insaeng/domain/result.dart';

void main() {
  group(GenericActionRepositoryImpl, () {
    test('perform returns not found for every endpoint', () async {
      const repository = GenericActionRepositoryImpl();

      final result = await repository.perform(method: RequestMethod.post, endpoint: '/anything', body: {'a': 1});

      expect(
        result,
        isA<Err<List<GenericAction>>>().having((err) => err.failure, 'failure', isA<GenericActionNotFound>()),
      );
    });
  });
}
