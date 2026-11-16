import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/data/repositories/my_day_page_mapper.dart';
import 'package:insaeng/data/repositories/widget_snapshot_repository_impl.dart';
import 'package:insaeng/data/services/home_widget_service.dart';
import 'package:insaeng/domain/models/generic_ui/generic_page.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/home_widget/widget_snapshot.dart';
import 'package:insaeng/domain/repositories/widget_snapshot_repository.dart';
import 'package:insaeng/domain/result.dart';
import 'package:mocktail/mocktail.dart';

class _MockHomeWidgetService extends Mock implements HomeWidgetService;

const String _pageId = MyDayPageMapper.widgetPageId;

const WidgetSnapshot _snapshot = WidgetSnapshot(
  pageId: _pageId,
  root: WidgetNode(
    type: 'column',
    id: 'root',
    children: [
      WidgetNode(type: 'text', id: 'title', props: {'text': 'My Day'}, tap: OpenAppTap()),
      WidgetNode(
        type: 'checkboxTile',
        id: 'task-1',
        props: {'title': 'Write tests', 'checked': false},
        tap: EventTap(nodeId: 'task-1', event: 'onChanged'),
      ),
    ],
  ),
);

final GenericPage _page = MyDayPageMapper.widgetFromRows([
  {
    'object': 'page',
    'id': 'task-1',
    'icon': {'type': 'emoji', 'emoji': '🧪'},
    'properties': {
      'Name': {
        'type': 'title',
        'title': [
          {'type': 'text', 'plain_text': 'Write tests'},
        ],
      },
      'Date': {
        'type': 'date',
        'date': {'start': '2026-11-15T09:00:00.000', 'end': '2026-11-15T10:00:00.000', 'time_zone': null},
      },
      'Status': {
        'type': 'status',
        'status': {'name': 'Not started'},
      },
    },
  },
], now: DateTime(2026, 11, 15, 12));

void main() {
  group(WidgetSnapshotRepositoryImpl, () {
    late HomeWidgetService service;
    late WidgetSnapshotRepository repository;
    late Map<String, String?> stored;

    setUp(() {
      service = _MockHomeWidgetService();
      repository = WidgetSnapshotRepositoryImpl(service);
      stored = {};
      when(() => service.save(any(), any())).thenAnswer((invocation) async {
        stored[invocation.positionalArguments[0] as String] = invocation.positionalArguments[1] as String?;
        return true;
      });
      when(() => service.read(any())).thenAnswer((invocation) async => stored[invocation.positionalArguments[0]]);
      when(() => service.update()).thenAnswer((_) async => true);
    });

    Future<Result<void>> save([GenericValues? values]) =>
        repository.save(_snapshot, page: _page, values: values ?? _page.initialState);

    group('save', () {
      test('stores the snapshot JSON under the snapshot key', () async {
        expect(await save(), const Result<void>.ok(null));

        final json = stored[WidgetSnapshotRepositoryImpl.snapshotKey(_pageId)]!;
        expect(WidgetSnapshotMapper.fromJson(json), _snapshot);
      });

      test('stores the page and values JSON under the page key', () async {
        await save();

        final json = jsonDecode(stored[WidgetSnapshotRepositoryImpl.pageKey(_pageId)]!) as Map<String, Object?>;
        expect(json.keys, unorderedEquals(['page', 'values']));
        expect(GenericPageMapper.fromMap(json['page']! as Map<String, Object?>), _page);
        expect(GenericValues(json['values']! as Map<String, Object?>), _page.initialState);
      });

      test('keeps each page id under its own keys', () {
        expect(WidgetSnapshotRepositoryImpl.snapshotKey('a'), isNot(WidgetSnapshotRepositoryImpl.snapshotKey('b')));
        expect(WidgetSnapshotRepositoryImpl.pageKey('a'), isNot(WidgetSnapshotRepositoryImpl.pageKey('b')));
        expect(WidgetSnapshotRepositoryImpl.snapshotKey('a'), isNot(WidgetSnapshotRepositoryImpl.pageKey('a')));
      });

      test('returns a platform error when the service throws a PlatformException', () async {
        when(() => service.save(any(), any())).thenThrow(PlatformException(code: 'save'));

        expect(await save(), const Result<void>.err(WidgetSnapshotPlatformError()));
      });

      test('returns a platform error when the plugin is missing', () async {
        when(() => service.save(any(), any())).thenThrow(MissingPluginException());

        expect(await save(), const Result<void>.err(WidgetSnapshotPlatformError()));
      });

      test('returns a platform error when the service reports that it did not save', () async {
        when(() => service.save(any(), any())).thenAnswer((_) async => false);

        expect(await save(), const Result<void>.err(WidgetSnapshotPlatformError()));
      });
    });

    group('load', () {
      test('returns the saved page and values', () async {
        await save();

        expect(await repository.load(_pageId), Result<WidgetPageState>.ok((page: _page, values: _page.initialState)));
      });

      test('returns the latest values rather than the page initial state', () async {
        final values = switch (_page.initialState.set('tasks.task-1.done', true)) {
          Ok(:final value) => value,
          Err() => fail('set failed'),
        };
        await save(values);

        expect(await repository.load(_pageId), Result<WidgetPageState>.ok((page: _page, values: values)));
      });

      test('returns not found when nothing is stored for the page id', () async {
        expect(await repository.load(_pageId), const Result<WidgetPageState>.err(WidgetSnapshotNotFound()));
      });

      test('returns not found for a page id other than the saved one', () async {
        await save();

        expect(await repository.load('other'), const Result<WidgetPageState>.err(WidgetSnapshotNotFound()));
      });

      for (final (description, raw) in [
        ('not JSON', 'not json'),
        ('not an object', '[]'),
        ('missing values', jsonEncode({'page': _page.toMap()})),
        ('an invalid page', jsonEncode({'page': 42, 'values': <String, Object?>{}})),
        (
          'a page that fails to decode',
          jsonEncode({
            'page': {'root': 'nope'},
            'values': <String, Object?>{},
          }),
        ),
      ]) {
        test('returns invalid when the stored entry is $description', () async {
          stored[WidgetSnapshotRepositoryImpl.pageKey(_pageId)] = raw;

          expect(await repository.load(_pageId), const Result<WidgetPageState>.err(WidgetSnapshotInvalid()));
        });
      }

      test('returns a platform error when the service throws a PlatformException', () async {
        when(() => service.read(any())).thenThrow(PlatformException(code: 'read'));

        expect(await repository.load(_pageId), const Result<WidgetPageState>.err(WidgetSnapshotPlatformError()));
      });
    });

    group('update', () {
      test('asks the service to update the widget', () async {
        expect(await repository.update(), const Result<void>.ok(null));

        verify(() => service.update()).called(1);
      });

      test('returns a platform error when the service throws a PlatformException', () async {
        when(() => service.update()).thenThrow(PlatformException(code: 'update'));

        expect(await repository.update(), const Result<void>.err(WidgetSnapshotPlatformError()));
      });

      test('returns a platform error when the service reports that it did not update', () async {
        when(() => service.update()).thenAnswer((_) async => false);

        expect(await repository.update(), const Result<void>.err(WidgetSnapshotPlatformError()));
      });
    });
  });
}
