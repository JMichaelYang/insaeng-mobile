import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:insaeng/data/repositories/generic_notion_action_repository_impl.dart';
import 'package:insaeng/data/services/notion_service.dart';
import 'package:insaeng/data/services/secure_storage_service.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/repositories/generic_action_repository.dart';
import 'package:insaeng/domain/result.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorageService extends Mock implements SecureStorageService;

class _MockNotionService extends Mock implements NotionService;

void main() {
  group(GenericNotionActionRepositoryImpl, () {
    late SecureStorageService storage;
    late NotionService notion;
    late GenericActionRepository repository;

    setUp(() {
      storage = _MockSecureStorageService();
      notion = _MockNotionService();
      repository = GenericNotionActionRepositoryImpl(storage, notion);
      when(() => storage.write(any(), any())).thenAnswer((_) async {});
      when(() => storage.read(any())).thenAnswer((_) async => 'secret');
      when(() => notion.updatePage(any(), any(), any())).thenAnswer((_) async => const {});
    });

    group('PUT /notion/token', () {
      Future<Result<List<GenericAction>>> put(Map<String, Object?> body) =>
          repository.perform(method: RequestMethod.put, endpoint: '/notion/token', body: body);

      test('saves the token and reloads', () async {
        expect(await put({'token': 'secret'}), const Result<List<GenericAction>>.ok([ReloadAction()]));
        verify(() => storage.write(SecureStorageService.notionTokenKey, 'secret')).called(1);
      });

      test('trims whitespace around the token', () async {
        await put({'token': '  secret\n'});

        verify(() => storage.write(SecureStorageService.notionTokenKey, 'secret')).called(1);
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

    group('PATCH /my-day/tasks/{id}', () {
      Future<Result<List<GenericAction>>> patch(Map<String, Object?> body, {String id = 'page-1'}) =>
          repository.perform(method: RequestMethod.patch, endpoint: '/my-day/tasks/$id', body: body);

      Map<String, Object?> statusProperties(String name) => {
        'Status': {
          'status': {'name': name},
        },
      };

      test('sets the status to Done when done is true', () async {
        expect(await patch({'done': true}), const Result<List<GenericAction>>.ok([]));
        verify(() => notion.updatePage('secret', 'page-1', statusProperties('Done'))).called(1);
      });

      test('sets the status to To do when done is false', () async {
        expect(await patch({'done': false}), const Result<List<GenericAction>>.ok([]));
        verify(() => notion.updatePage('secret', 'page-1', statusProperties('To do'))).called(1);
      });

      test('reads the token from storage', () async {
        await patch({'done': true});

        verify(() => storage.read(SecureStorageService.notionTokenKey)).called(1);
      });

      for (final (description, body) in [
        ('missing', const <String, Object?>{}),
        ('null', const <String, Object?>{'done': null}),
        ('not a bool', const <String, Object?>{'done': 'true'}),
      ]) {
        test('returns invalid when done is $description', () async {
          expect(await patch(body), const Result<List<GenericAction>>.err(GenericActionInvalid()));
          verifyNever(() => notion.updatePage(any(), any(), any()));
        });
      }

      for (final token in [null, '']) {
        test('returns unauthorized when the stored token is ${token == null ? 'missing' : 'empty'}', () async {
          when(() => storage.read(any())).thenAnswer((_) async => token);

          expect(await patch({'done': true}), const Result<List<GenericAction>>.err(GenericActionUnauthorized()));
          verifyNever(() => notion.updatePage(any(), any(), any()));
        });
      }

      test('returns server error when reading the token fails', () async {
        when(() => storage.read(any())).thenThrow(PlatformException(code: 'error'));

        expect(await patch({'done': true}), const Result<List<GenericAction>>.err(GenericActionServerError()));
        verifyNever(() => notion.updatePage(any(), any(), any()));
      });

      for (final (exception, failure) in <(Exception, GenericActionFailure)>[
        (const NotionUnauthorizedException(), const GenericActionUnauthorized()),
        (NotionNetworkException(ClientException('offline')), const GenericActionOffline()),
        (const NotionRateLimitedException(), const GenericActionServerError()),
        (const NotionHttpException(500, 'error'), const GenericActionServerError()),
        (const FormatException('bad json'), const GenericActionServerError()),
      ]) {
        test('returns ${failure.runtimeType} when Notion throws ${exception.runtimeType}', () async {
          when(() => notion.updatePage(any(), any(), any())).thenThrow(exception);

          expect(await patch({'done': true}), Result<List<GenericAction>>.err(failure));
        });
      }
    });

    for (final (method, endpoint) in [
      (RequestMethod.post, '/notion/token'),
      (RequestMethod.put, '/notion/other'),
      (RequestMethod.get, '/anything'),
      (RequestMethod.put, '/my-day/tasks/page-1'),
      (RequestMethod.patch, '/my-day/tasks/'),
      (RequestMethod.patch, '/my-day/tasks/page-1/extra'),
    ]) {
      test('returns not found for ${method.name.toUpperCase()} $endpoint', () async {
        expect(
          await repository.perform(method: method, endpoint: endpoint, body: const {'token': 'secret', 'done': true}),
          const Result<List<GenericAction>>.err(GenericActionNotFound()),
        );
        verifyNever(() => storage.write(any(), any()));
        verifyNever(() => notion.updatePage(any(), any(), any()));
      });
    }
  });
}
