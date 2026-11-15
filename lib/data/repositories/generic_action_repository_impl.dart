import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/repositories/generic_action_repository.dart';
import 'package:insaeng/domain/result.dart';

final class GenericActionRepositoryImpl implements GenericActionRepository {
  const new();

  @override
  Future<Result<List<GenericAction>>> perform({
    required RequestMethod method,
    required String endpoint,
    Map<String, Object?> body = const {},
  }) async => const Result.err(GenericActionNotFound());
}
