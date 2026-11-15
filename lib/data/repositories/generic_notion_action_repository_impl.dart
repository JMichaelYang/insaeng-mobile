import 'package:flutter/services.dart';
import 'package:insaeng/data/services/notion_service.dart';
import 'package:insaeng/data/services/secure_storage_service.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/repositories/generic_action_repository.dart';
import 'package:insaeng/domain/result.dart';

final class GenericNotionActionRepositoryImpl implements GenericActionRepository {
  const new(this._storage, this._notion);

  static const tokenKey = 'notion_token';
  static const doneStatus = 'Done';
  static const todoStatus = 'To do';

  final SecureStorageService _storage;
  final NotionService _notion;

  @override
  Future<Result<List<GenericAction>>> perform({
    required RequestMethod method,
    required String endpoint,
    Map<String, Object?> body = const {},
  }) => switch ((method, endpoint.split('/'))) {
    (RequestMethod.put, ['', 'notion', 'token']) => _saveToken(body),
    (RequestMethod.patch, ['', 'my-day', 'tasks', final id]) when id.isNotEmpty => _updateTaskStatus(id, body),
    _ => Future.value(const Result.err(GenericActionNotFound())),
  };

  Future<Result<List<GenericAction>>> _saveToken(Map<String, Object?> body) async {
    final token = switch (body['token']) {
      final String value => value.trim(),
      _ => '',
    };
    if (token.isEmpty) return const Result.err(GenericActionInvalid());
    try {
      await _storage.write(tokenKey, token);
      return const Result.ok([ReloadAction()]);
    } on PlatformException {
      return const Result.err(GenericActionServerError());
    }
  }

  Future<Result<List<GenericAction>>> _updateTaskStatus(String id, Map<String, Object?> body) async {
    final status = switch (body['done']) {
      true => doneStatus,
      false => todoStatus,
      _ => null,
    };
    if (status == null) return const Result.err(GenericActionInvalid());
    try {
      final token = await _storage.read(tokenKey);
      if (token == null || token.isEmpty) return const Result.err(GenericActionUnauthorized());
      await _notion.updatePage(token, id, {
        'Status': {
          'status': {'name': status},
        },
      });
      return const Result.ok([]);
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
}
