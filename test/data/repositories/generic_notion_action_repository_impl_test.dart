import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/data/repositories/generic_notion_action_repository_impl.dart';
import 'package:insaeng/data/services/secure_storage_service.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/repositories/generic_action_repository.dart';
import 'package:insaeng/domain/result.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorageService extends Mock implements SecureStorageService;

void main() {
  group(GenericNotionActionRepositoryImpl, () {
    late SecureStorageService storage;
    late GenericActionRepository repository;

    setUp(() {
      storage = _MockSecureStorageService();
      repository = GenericNotionActionRepositoryImpl(storage);
      when(() => storage.write(any(), any())).thenAnswer((_) async {});
    });

    group('PUT /notion/token', () {
      Future<Result<List<GenericAction>>> put(Map<String, Object?> body) =>
          repository.perform(method: RequestMethod.put, endpoint: '/notion/token', body: body);

      test('saves the token and reloads', () async {
        expect(await put({'token': 'secret'}), const Result<List<GenericAction>>.ok([ReloadAction()]));
        verify(() => storage.write(GenericNotionActionRepositoryImpl.tokenKey, 'secret')).called(1);
      });

      test('trims whitespace around the token', () async {
        await put({'token': '  secret\n'});

        verify(() => storage.write(GenericNotionActionRepositoryImpl.tokenKey, 'secret')).called(1);
      });

      for (final (description, body) in [
        ('missing', const <String, Object?>{}),
        ('null', const <String, Object?>{'token': null}),
        ('blank', const <String, Object?>{'token': '  '}),
        ('not a string', const <String, Object?>{'token': 42}),
      ]) {
        test('returns invalid when the token is $description', () async {
          expect(await put(body), const Result<List<GenericAction>>.err(GenericActionInvalid()));
          verifyNever(() => storage.write(any(), any()));
        });
      }

      test('returns server error when storage fails', () async {
        when(() => storage.write(any(), any())).thenThrow(PlatformException(code: 'error'));

        expect(await put({'token': 'secret'}), const Result<List<GenericAction>>.err(GenericActionServerError()));
      });
    });

    for (final (method, endpoint) in [
      (RequestMethod.post, '/notion/token'),
      (RequestMethod.put, '/notion/other'),
      (RequestMethod.get, '/anything'),
    ]) {
      test('returns not found for ${method.name.toUpperCase()} $endpoint', () async {
        expect(
          await repository.perform(method: method, endpoint: endpoint, body: const {'token': 'secret'}),
          const Result<List<GenericAction>>.err(GenericActionNotFound()),
        );
        verifyNever(() => storage.write(any(), any()));
      });
    }
  });
}
