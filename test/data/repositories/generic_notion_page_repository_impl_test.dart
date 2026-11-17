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
final _today = DateTime(2026, 3);

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

      void stub({String? token = 'secret', String? dataSourceId = 'agenda', String? selectedDay}) {
        when(() => storage.read(SecureStorageService.notionTokenKey)).thenAnswer((_) async => token);
        when(() => storage.read(SecureStorageService.notionDataSourceIdKey)).thenAnswer((_) async => dataSourceId);
        when(() => storage.read(SecureStorageService.myDaySelectedDayKey(MyDayPageMapper.pageId)))
            .thenAnswer((_) async => selectedDay);
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

      Map<String, Object?> queryBody({String? cursor, String after = '2026-02-28', String before = '2026-03-02'}) => {
        'filter': {
          'and': [
            {
              'property': GenericNotionPageRepositoryImpl.dateProperty,
              'date': {'on_or_after': after},
            },
            {
              'property': GenericNotionPageRepositoryImpl.dateProperty,
              'date': {'on_or_before': before},
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

        expect(await fetch(), Result<GenericPage>.ok(MyDayPageMapper.fromRows(rows, day: _today, today: _today)));
        verify(() => notion.queryDataSource('secret', 'agenda', queryBody())).called(1);
      });

      test('queries around the stored day and maps the rows for it', () async {
        stub(selectedDay: '2026-03-05');
        final rows = [_row('today', '2026-03-01'), _row('selected', '2026-03-05')];
        stubQuery((_) async => _response(rows));

        final page = _page(await fetch());

        expect(page, MyDayPageMapper.fromRows(rows, day: DateTime(2026, 3, 5), today: _today));
        expect([for (final tile in page.nodes.whereType<CheckboxTileNode>()) tile.id], ['task-selected']);
        verify(() => notion.queryDataSource('secret', 'agenda', queryBody(after: '2026-03-04', before: '2026-03-06')))
            .called(1);
      });

      for (final (description, stored, day, after, before) in [
        ('more than seven days back', '2026-02-01', DateTime(2026, 2, 22), '2026-02-21', '2026-02-23'),
        ('more than seven days ahead', '2026-03-20', DateTime(2026, 3, 8), '2026-03-07', '2026-03-09'),
      ]) {
        test('clamps a stored day $description to the nearest bound', () async {
          stub(selectedDay: stored);
          stubQuery((_) async => _response(const []));

          expect(await fetch(), Result<GenericPage>.ok(MyDayPageMapper.fromRows(const [], day: day, today: _today)));
          verify(() => notion.queryDataSource('secret', 'agenda', queryBody(after: after, before: before))).called(1);
        });
      }

      test('falls back to today when the stored day is malformed', () async {
        stub(selectedDay: 'tomorrow');
        stubQuery((_) async => _response(const []));

        expect(await fetch(), Result<GenericPage>.ok(MyDayPageMapper.fromRows(const [], day: _today, today: _today)));
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

        expect(
          await fetch(),
          Result<GenericPage>.ok(MyDayPageMapper.fromRows([first, second], day: _today, today: _today)),
        );
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

    group(MyDayPageMapper.widgetPageId, () {
      Future<Result<GenericPage>> fetch() => repository.fetch(MyDayPageMapper.widgetPageId, const {});

      void stub({String? token = 'secret', String? dataSourceId = 'agenda', String? selectedDay}) {
        when(() => storage.read(SecureStorageService.notionTokenKey)).thenAnswer((_) async => token);
        when(() => storage.read(SecureStorageService.notionDataSourceIdKey)).thenAnswer((_) async => dataSourceId);
        when(() => storage.read(SecureStorageService.myDaySelectedDayKey(MyDayPageMapper.widgetPageId)))
            .thenAnswer((_) async => selectedDay);
      }

      void stubQuery(Future<Map<String, Object?>> Function(Invocation invocation) answer) =>
          when(() => notion.queryDataSource(any(), any(), any())).thenAnswer(answer);

      test('maps the same agenda query to the widget page', () async {
        stub();
        final first = _row('first', '2026-03-01');
        final second = _row('second', '2026-03-02');
        stubQuery(
          (invocation) async => switch ((invocation.positionalArguments[2] as Map<String, Object?>)['start_cursor']) {
            null => _response([first], nextCursor: 'cursor-2'),
            _ => _response([second]),
          },
        );

        expect(
          await fetch(),
          Result<GenericPage>.ok(MyDayPageMapper.widgetFromRows([first, second], day: _today, today: _today)),
        );
        verify(
          () => notion.queryDataSource('secret', 'agenda', {
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
          }),
        ).called(1);
        verify(() => notion.queryDataSource('secret', 'agenda', any(that: containsPair('start_cursor', 'cursor-2'))))
            .called(1);
      });

      test('reads the widget day separately from the app day', () async {
        stub(selectedDay: '2026-02-27');
        when(() => storage.read(SecureStorageService.myDaySelectedDayKey(MyDayPageMapper.pageId)))
            .thenAnswer((_) async => '2026-03-05');
        stubQuery((_) async => _response(const []));

        expect(
          await fetch(),
          Result<GenericPage>.ok(MyDayPageMapper.widgetFromRows(const [], day: DateTime(2026, 2, 27), today: _today)),
        );
        verifyNever(() => storage.read(SecureStorageService.myDaySelectedDayKey(MyDayPageMapper.pageId)));
      });

      test('clamps a stored widget day outside the window', () async {
        stub(selectedDay: '2027-01-01');
        stubQuery((_) async => _response(const []));

        expect(
          await fetch(),
          Result<GenericPage>.ok(MyDayPageMapper.widgetFromRows(const [], day: DateTime(2026, 3, 8), today: _today)),
        );
      });

      test('returns the empty widget page when no rows match', () async {
        stub();
        stubQuery((_) async => _response(const []));

        final page = _page(await fetch());

        expect(page, MyDayPageMapper.widgetFromRows(const [], day: _today, today: _today));
        expect(page.nodes.whereType<TextNode>().single.text, const Literal(MyDayPageMapper.emptyText));
      });

      for (final (description, token, dataSourceId) in [
        ('the token is missing', null, 'agenda'),
        ('the data source id is empty', 'secret', ''),
      ]) {
        test('returns the widget connect page when $description', () async {
          stub(token: token, dataSourceId: dataSourceId);

          expect(await fetch(), const Result<GenericPage>.ok(MyDayPageMapper.widgetConnectPage));
          verifyZeroInteractions(notion);
        });
      }

      test('returns the widget connect page when Notion rejects the token', () async {
        stub();
        stubQuery((_) async => throw const NotionUnauthorizedException());

        expect(await fetch(), const Result<GenericPage>.ok(MyDayPageMapper.widgetConnectPage));
      });

      for (final (description, exception, failure) in [
        ('the network fails', NotionNetworkException(ClientException('offline')), const GenericPageOffline()),
        ('Notion returns an HTTP error', const NotionHttpException(500, 'error'), const GenericPageServerError()),
        ('Notion returns malformed JSON', const FormatException('bad'), const GenericPageServerError()),
      ]) {
        test('returns $failure when $description', () async {
          stub();
          stubQuery((_) async => throw exception);

          expect(await fetch(), Result<GenericPage>.err(failure));
        });
      }

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
