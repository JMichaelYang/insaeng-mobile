import 'package:flutter/services.dart';
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

final class GenericNotionPageRepositoryImpl implements GenericPageRepository {
  const new(this._storage, this._notion, {this._now = DateTime.now});

  static const connectTitle = 'Connect Notion';
  static const connectDescription = 'Paste a Notion integration token and the ID of your agenda data source.';
  static const tokenLabel = 'Notion token';
  static const dataSourceIdLabel = 'Agenda data source ID';
  static const connectLabel = 'Connect';
  static const connectErrorText = "Couldn't connect Notion. Check both fields and try again.";

  static final GenericPage connectPage = GenericPage(
    id: MyDayPageMapper.pageId,
    state: GenericValues(const {
      'notion': {'token': '', 'dataSourceId': ''},
      'saving': false,
    }),
    root: const ColumnNode(
      id: 'root',
      children: [
        AppBarNode(id: 'appBar', title: Literal(MyDayPageMapper.title)),
        ExpandedNode(
          id: 'body',
          child: ScrollNode(
            id: 'scroll',
            child: ContainerNode(
              id: 'content',
              padding: Literal(SpacingToken.lg),
              child: ColumnNode(
                id: 'connect',
                spacing: Literal(SpacingToken.md),
                alignment: Literal(AlignmentToken.stretch),
                children: [
                  TextNode(id: 'connectTitle', text: Literal(connectTitle), style: Literal(TextStyleToken.titleLarge)),
                  TextNode(id: 'connectDescription', text: Literal(connectDescription)),
                  TextFieldNode(id: 'token', bind: 'notion.token', label: Literal(tokenLabel), secure: Literal(true)),
                  TextFieldNode(id: 'dataSourceId', bind: 'notion.dataSourceId', label: Literal(dataSourceIdLabel)),
                  ButtonNode(
                    id: 'connectButton',
                    label: Literal(connectLabel),
                    loading: Binding('saving', fallback: false),
                    onTap: [
                      UpdateStateAction(path: 'saving', value: Literal(true)),
                      RequestAction(
                        method: Literal(RequestMethod.put),
                        endpoint: Literal('/notion/connection'),
                        body: JsonObject({
                          'token': JsonBinding(Binding('notion.token')),
                          'dataSourceId': JsonBinding(Binding('notion.dataSourceId')),
                        }),
                        onError: [ShowMessageAction(text: Literal(connectErrorText))],
                        onComplete: [UpdateStateAction(path: 'saving', value: Literal(false))],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  static const dateProperty = 'Date';
  static const pageSize = 100;

  final SecureStorageService _storage;
  final NotionService _notion;
  final DateTime Function() _now;

  @override
  Future<Result<GenericPage>> fetch(String id, Map<String, String> params) => switch (id) {
    MyDayPageMapper.pageId => _myDay(),
    _ => Future.value(const Result.err(GenericPageNotFound())),
  };

  Future<Result<GenericPage>> _myDay() async {
    final String? token;
    final String? dataSourceId;
    try {
      token = await _storage.read(SecureStorageService.notionTokenKey);
      dataSourceId = await _storage.read(SecureStorageService.notionDataSourceIdKey);
    } on PlatformException {
      return const Result.err(GenericPageServerError());
    }
    if (token == null || token.isEmpty || dataSourceId == null || dataSourceId.isEmpty) {
      return Result.ok(connectPage);
    }
    final now = _now();
    try {
      final rows = await _agendaRows(token, dataSourceId, now);
      return Result.ok(MyDayPageMapper.fromRows(rows, now: now));
    } on NotionUnauthorizedException {
      return Result.ok(connectPage);
    } on NotionNetworkException {
      return const Result.err(GenericPageOffline());
    } on NotionException {
      return const Result.err(GenericPageServerError());
    } on FormatException {
      return const Result.err(GenericPageServerError());
    }
  }

  Future<List<Map<String, Object?>>> _agendaRows(String token, String dataSourceId, DateTime now) async {
    final filter = {
      'and': [
        {
          'property': dateProperty,
          'date': {'on_or_after': _date(DateTime(now.year, now.month, now.day - 1))},
        },
        {
          'property': dateProperty,
          'date': {'on_or_before': _date(DateTime(now.year, now.month, now.day + 1))},
        },
      ],
    };
    final rows = <Map<String, Object?>>[];
    String? cursor;
    do {
      final response = await _notion.queryDataSource(token, dataSourceId, {
        'filter': filter,
        'page_size': pageSize,
        'start_cursor': ?cursor,
      });
      rows.addAll(switch (response['results']) {
        final List<Object?> results => results.whereType<Map<String, Object?>>(),
        _ => throw FormatException('Expected a results list', response),
      });
      cursor = switch (response) {
        {'has_more': true, 'next_cursor': final String next} => next,
        _ => null,
      };
    } while (cursor != null);
    return rows;
  }

  static String _date(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
}
