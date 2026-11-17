import 'package:flutter/services.dart';
import 'package:insaeng/data/repositories/my_day_page_mapper.dart';
import 'package:insaeng/data/services/notion_service.dart';
import 'package:insaeng/data/services/secure_storage_service.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/repositories/generic_action_repository.dart';
import 'package:insaeng/domain/result.dart';

final class GenericNotionActionRepositoryImpl implements GenericActionRepository {
  const new(this._storage, this._notion, {this._now = DateTime.now});

  static const doneStatus = 'Done';
  static const todoStatus = 'To do';

  static const connectionEndpoint = '/notion/connection';

  static const Set<String> _myDayPageIds = {MyDayPageMapper.pageId, MyDayPageMapper.widgetPageId};

  final SecureStorageService _storage;
  final NotionService _notion;
  final DateTime Function() _now;

  @override
  Future<Result<List<GenericAction>>> perform({
    required RequestMethod method,
    required String endpoint,
    Map<String, Object?> body = const {},
  }) => switch ((method, endpoint.split('/'))) {
    (RequestMethod.put, _) when endpoint == connectionEndpoint => _saveConnection(body),
    (RequestMethod.patch, ['', 'my-day', 'tasks', final id]) when id.isNotEmpty => _updateTaskStatus(id, body),
    (RequestMethod.put, _) when endpoint == MyDayPageMapper.selectedDayEndpoint => _selectDay(body),
    _ => Future.value(const Result.err(GenericActionNotFound())),
  };

  Future<Result<List<GenericAction>>> _saveConnection(Map<String, Object?> body) async {
    final token = _trimmed(body['token']);
    final dataSourceId = _trimmed(body['dataSourceId']);
    if (token.isEmpty || dataSourceId.isEmpty) return const Result.err(GenericActionInvalid());
    try {
      await _storage.write(SecureStorageService.notionTokenKey, token);
      await _storage.write(SecureStorageService.notionDataSourceIdKey, dataSourceId);
      return const Result.ok([ReloadAction()]);
    } on PlatformException {
      return const Result.err(GenericActionServerError());
    }
  }

  Future<Result<List<GenericAction>>> _selectDay(Map<String, Object?> body) async {
    final pageId = body['pageId'];
    final day = MyDayPageMapper.parseDate(body['date']);
    if (pageId is! String || !_myDayPageIds.contains(pageId) || day == null) {
      return const Result.err(GenericActionInvalid());
    }
    final selected = MyDayPageMapper.clampDay(day, today: MyDayPageMapper.dateOf(_now()));
    try {
      await _storage.write(SecureStorageService.myDaySelectedDayKey(pageId), MyDayPageMapper.formatDate(selected));
      return const Result.ok([ReloadAction()]);
    } on PlatformException {
      return const Result.err(GenericActionServerError());
    }
  }

  Future<Result<List<GenericAction>>> _updateTaskStatus(String id, Map<String, Object?> body) async {
    final done = body['done'];
    if (done is! bool) return const Result.err(GenericActionInvalid());
    final status = done ? doneStatus : todoStatus;
    try {
      final token = await _storage.read(SecureStorageService.notionTokenKey);
      if (token == null || token.isEmpty) return const Result.err(GenericActionUnauthorized());
      await _notion.updatePage(token, id, {
        'Status': {
          'status': {'name': status},
        },
      });
      return Result.ok([
        UpdateStateAction(
          path: MyDayPageMapper.progressDonePath,
          op: const Literal(UpdateOp.increment),
          value: Literal(done ? 1 : -1),
        ),
      ]);
    } on PlatformException {
      return const Result.err(GenericActionServerError());
    } on NotionUnauthorizedException {
      return const Result.err(GenericActionUnauthorized());
    } on NotionNetworkException {
      return const Result.err(GenericActionOffline());
    } on NotionException {
      return const Result.err(GenericActionServerError());
    } on FormatException {
      return const Result.err(GenericActionServerError());
    }
  }

  static String _trimmed(Object? value) => switch (value) {
    final String value => value.trim(),
    _ => '',
  };
}
