import 'package:flutter/services.dart';
import 'package:insaeng/data/services/secure_storage_service.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/repositories/generic_action_repository.dart';
import 'package:insaeng/domain/result.dart';

final class GenericNotionActionRepositoryImpl implements GenericActionRepository {
  const new(this._storage);

  static const tokenKey = 'notion_token';

  final SecureStorageService _storage;

  @override
  Future<Result<List<GenericAction>>> perform({
    required RequestMethod method,
    required String endpoint,
    Map<String, Object?> body = const {},
  }) => switch ((method, endpoint)) {
    (RequestMethod.put, '/notion/token') => _saveToken(body),
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
}
