import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:insaeng/data/repositories/generic_notion_action_repository_impl.dart';
import 'package:insaeng/data/repositories/generic_notion_page_repository_impl.dart';
import 'package:insaeng/data/repositories/my_day_page_mapper.dart';
import 'package:insaeng/data/services/notion_service.dart';
import 'package:insaeng/data/services/secure_storage_service.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/bindable_json.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_page.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/domain/repositories/generic_page_repository.dart';
import 'package:insaeng/domain/result.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorageService extends Mock implements SecureStorageService;

class _MockNotionService extends Mock implements NotionService;

final _now = DateTime(2026, 3, 1, 9);

Map<String, Object?> _row(String id, String start) => {
  'object': 'page',
  'id': id,
  'properties': {
    'Name': {
      'type': 'title',
      'title': [
        {'type': 'text', 'plain_text': id},
      ],
    },
    'Date': {
      'type': 'date',
      'date': {'start': start, 'end': null, 'time_zone': null},
    },
    'Status': {
      'type': 'status',
      'status': {'name': 'To do'},
    },
  },
};

Map<String, Object?> _response(List<Map<String, Object?>> rows, {String? nextCursor}) => {
  'object': 'list',
  'results': rows,
  'has_more': nextCursor != null,
  'next_cursor': nextCursor,
};

GenericPage _page(Result<GenericPage> result) => switch (result) {
  Ok(value: final page) => page,
  Err(:final failure) => throw TestFailure('Expected a page, got $failure'),
};

void main() {
  group(GenericNotionPageRepositoryImpl, () {
    late SecureStorageService storage;
    late NotionService notion;
    late GenericPageRepository repository;

    setUp(() {
      storage = _MockSecureStorageService();
      notion = _MockNotionService();
      repository = GenericNotionPageRepositoryImpl(storage, notion, now: () => _now);
    });

    group(MyDayPageMapper.pageId, () {
      Future<Result<GenericPage>> fetch() => repository.fetch(MyDayPageMapper.pageId, const {});

      void stub({String? token = 'secret', String? dataSourceId = 'agenda'}) {
        when(() => storage.read(SecureStorageService.notionTokenKey)).thenAnswer((_) async => token);
        when(() => storage.read(SecureStorageService.notionDataSourceIdKey)).thenAnswer((_) async => dataSourceId);
      }

      for (final (description, value) in [('missing', null), ('empty', '')]) {
        test('returns the connect page when the token is $description', () async {
          stub(token: value);

          expect(await fetch(), Result<GenericPage>.ok(GenericNotionPageRepositoryImpl.connectPage));
          verifyZeroInteractions(notion);
        });

        test('returns the connect page when the data source id is $description', () async {
          stub(dataSourceId: value);

          expect(await fetch(), Result<GenericPage>.ok(GenericNotionPageRepositoryImpl.connectPage));
          verifyZeroInteractions(notion);
        });
      }

      void stubQuery(Future<Map<String, Object?>> Function(Invocation invocation) answer) =>
          when(() => notion.queryDataSource(any(), any(), any())).thenAnswer(answer);

      Map<String, Object?> queryBody({String? cursor}) => {
        'filter': {
          'and': [
            {
              'property': GenericNotionPageRepositoryImpl.dateProperty,
              'date': {'on_or_after': '2026-02-28'},
            },
            {
              'property': GenericNotionPageRepositoryImpl.dateProperty,
              'date': {'on_or_before': '2026-03-02'},
            },
          ],
        },
        'page_size': GenericNotionPageRepositoryImpl.pageSize,
        'start_cursor': ?cursor,
      };

      test('queries the agenda from yesterday to tomorrow and maps the rows', () async {
        stub();
        final rows = [_row('yesterday', '2026-02-28'), _row('today', '2026-03-01'), _row('tomorrow', '2026-03-02')];
        stubQuery((_) async => _response(rows));

        expect(await fetch(), Result<GenericPage>.ok(MyDayPageMapper.fromRows(rows, now: _now)));
        verify(() => notion.queryDataSource('secret', 'agenda', queryBody())).called(1);
      });

      test('shows only the rows dated today', () async {
        stub();
        stubQuery(
          (_) async =>
              _response([_row('yesterday', '2026-02-28'), _row('today', '2026-03-01'), _row('tomorrow', '2026-03-02')]),
        );

        final page = _page(await fetch());

        expect([for (final tile in page.nodes.whereType<CheckboxTileNode>()) tile.id], ['task-today']);
      });

      test('follows the next cursor until every row is loaded', () async {
        stub();
        final first = _row('first', '2026-03-01');
        final second = _row('second', '2026-03-01');
        stubQuery(
          (invocation) async => switch ((invocation.positionalArguments[2] as Map<String, Object?>)['start_cursor']) {
            null => _response([first], nextCursor: 'cursor-2'),
            _ => _response([second]),
          },
        );

        expect(await fetch(), Result<GenericPage>.ok(MyDayPageMapper.fromRows([first, second], now: _now)));
        verify(() => notion.queryDataSource('secret', 'agenda', queryBody())).called(1);
        verify(() => notion.queryDataSource('secret', 'agenda', queryBody(cursor: 'cursor-2'))).called(1);
      });

      test('returns the empty My Day page when no rows match', () async {
        stub();
        stubQuery((_) async => _response(const []));

        final page = _page(await fetch());

        expect(page.id, MyDayPageMapper.pageId);
        expect(page.nodes.whereType<TextFieldNode>(), isEmpty);
        expect(page.nodes.whereType<TextNode>().single.text, const Literal(MyDayPageMapper.emptyText));
      });

      test('returns the connect page when Notion rejects the token', () async {
        stub();
        stubQuery((_) async => throw const NotionUnauthorizedException());

        expect(await fetch(), Result<GenericPage>.ok(GenericNotionPageRepositoryImpl.connectPage));
      });

      test('returns offline when the network fails', () async {
        stub();
        stubQuery((_) async => throw NotionNetworkException(ClientException('offline')));

        expect(await fetch(), const Result<GenericPage>.err(GenericPageOffline()));
      });

      for (final (description, exception) in [
        ('is rate limited', const NotionRateLimitedException()),
        ('returns an HTTP error', const NotionHttpException(500, 'error')),
        ('returns malformed JSON', const FormatException('bad')),
      ]) {
        test('returns server error when Notion $description', () async {
          stub();
          stubQuery((_) async => throw exception);

          expect(await fetch(), const Result<GenericPage>.err(GenericPageServerError()));
        });
      }

      test('returns server error when the response has no results list', () async {
        stub();
        stubQuery((_) async => const {'object': 'list'});

        expect(await fetch(), const Result<GenericPage>.err(GenericPageServerError()));
      });

      test('returns server error when storage fails', () async {
        when(() => storage.read(any())).thenThrow(PlatformException(code: 'error'));

        expect(await fetch(), const Result<GenericPage>.err(GenericPageServerError()));
      });
    });

    test('returns not found for other pages', () async {
      expect(await repository.fetch('home', const {}), const Result<GenericPage>.err(GenericPageNotFound()));
      verifyNever(() => storage.read(any()));
    });

    group('connectPage', () {
      final page = GenericNotionPageRepositoryImpl.connectPage;

      test('has unique node ids', () {
        final ids = [for (final node in page.nodes) node.id];

        expect(ids.toSet(), hasLength(ids.length));
      });

      test('starts with empty fields and no save in progress', () {
        expect(
          page.state,
          GenericValues(const {
            'notion': {'token': '', 'dataSourceId': ''},
            'saving': false,
          }),
        );
      });

      test('shows the My Day app bar', () {
        expect(page.nodes.whereType<AppBarNode>().single.title, const Literal(MyDayPageMapper.title));
      });

      test('binds a secure token field and a plain data source id field', () {
        final fields = {for (final field in page.nodes.whereType<TextFieldNode>()) field.bind: field.secure};

        expect(fields, const {'notion.token': Literal(true), 'notion.dataSourceId': Literal(false)});
      });

      test('saves both fields through the connection endpoint', () {
        final button = page.nodes.whereType<ButtonNode>().single;

        expect(button.loading, const Binding('saving', fallback: false));
        expect(button.onTap, const [
          UpdateStateAction(path: 'saving', value: Literal(true)),
          RequestAction(
            method: Literal(RequestMethod.put),
            endpoint: Literal(GenericNotionActionRepositoryImpl.connectionEndpoint),
            body: JsonObject({
              'token': JsonBinding(Binding('notion.token')),
              'dataSourceId': JsonBinding(Binding('notion.dataSourceId')),
            }),
            onError: [ShowMessageAction(text: Literal(GenericNotionPageRepositoryImpl.connectErrorText))],
            onComplete: [UpdateStateAction(path: 'saving', value: Literal(false))],
          ),
        ]);
      });
    });
  });
}
