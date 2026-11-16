import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:insaeng/data/repositories/generic_notion_action_repository_impl.dart';
import 'package:insaeng/data/repositories/my_day_page_mapper.dart';
import 'package:insaeng/data/services/notion_service.dart';
import 'package:insaeng/data/services/secure_storage_service.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/repositories/generic_action_repository.dart';
import 'package:insaeng/domain/result.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorageService extends Mock implements SecureStorageService;

class _MockNotionService extends Mock implements NotionService;

const _body = <String, Object?>{'token': 'secret', 'dataSourceId': 'agenda'};

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

    group('PUT ${GenericNotionActionRepositoryImpl.connectionEndpoint}', () {
      Future<Result<List<GenericAction>>> put(Map<String, Object?> body) => repository.perform(
        method: RequestMethod.put,
        endpoint: GenericNotionActionRepositoryImpl.connectionEndpoint,
        body: body,
      );

      test('saves the token and data source id and reloads', () async {
        expect(await put(_body), const Result<List<GenericAction>>.ok([ReloadAction()]));
        verify(() => storage.write(SecureStorageService.notionTokenKey, 'secret')).called(1);
        verify(() => storage.write(SecureStorageService.notionDataSourceIdKey, 'agenda')).called(1);
      });

      test('trims whitespace around both fields', () async {
        await put({'token': '  secret\n', 'dataSourceId': ' agenda '});

        verify(() => storage.write(SecureStorageService.notionTokenKey, 'secret')).called(1);
        verify(() => storage.write(SecureStorageService.notionDataSourceIdKey, 'agenda')).called(1);
      });

      for (final field in ['token', 'dataSourceId']) {
        for (final (description, value) in [('null', null), ('blank', '  '), ('not a string', 42)]) {
          test('returns invalid when $field is $description', () async {
            expect(await put({..._body, field: value}), const Result<List<GenericAction>>.err(GenericActionInvalid()));
            verifyNever(() => storage.write(any(), any()));
          });
        }

        test('returns invalid when $field is missing', () async {
          expect(await put({..._body}..remove(field)), const Result<List<GenericAction>>.err(GenericActionInvalid()));
          verifyNever(() => storage.write(any(), any()));
        });
      }

      test('returns server error when storage fails', () async {
        when(() => storage.write(any(), any())).thenThrow(PlatformException(code: 'error'));

        expect(await put(_body), const Result<List<GenericAction>>.err(GenericActionServerError()));
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

      Matcher progressBy(int step) => isA<Ok<List<GenericAction>>>().having((result) => result.value, 'value', [
        UpdateStateAction(
          path: MyDayPageMapper.progressDonePath,
          op: const Literal(UpdateOp.increment),
          value: Literal(step),
        ),
      ]);

      test('sets the status to Done and counts the task toward progress when done is true', () async {
        expect(await patch({'done': true}), progressBy(1));
        verify(() => notion.updatePage('secret', 'page-1', statusProperties('Done'))).called(1);
      });

      test('sets the status to To do and removes the task from progress when done is false', () async {
        expect(await patch({'done': false}), progressBy(-1));
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
      (RequestMethod.post, GenericNotionActionRepositoryImpl.connectionEndpoint),
      (RequestMethod.put, '/notion/token'),
      (RequestMethod.get, '/anything'),
      (RequestMethod.put, '/my-day/tasks/page-1'),
      (RequestMethod.patch, '/my-day/tasks/'),
      (RequestMethod.patch, '/my-day/tasks/page-1/extra'),
    ]) {
      test('returns not found for ${method.name.toUpperCase()} $endpoint', () async {
        expect(
          await repository.perform(method: method, endpoint: endpoint, body: const {..._body, 'done': true}),
          const Result<List<GenericAction>>.err(GenericActionNotFound()),
        );
        verifyNever(() => storage.write(any(), any()));
        verifyNever(() => notion.updatePage(any(), any(), any()));
      });
    }
  });
}
