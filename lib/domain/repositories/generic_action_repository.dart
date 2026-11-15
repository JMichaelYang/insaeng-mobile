import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/result.dart';

sealed class GenericActionFailure extends Failure {
  const new();
}

final class GenericActionNotFound extends GenericActionFailure {
  const new();
}

final class GenericActionOffline extends GenericActionFailure {
  const new();
}

final class GenericActionServerError extends GenericActionFailure {
  const new();
}

final class GenericActionInvalid extends GenericActionFailure {
  const new();
}

final class GenericActionUnauthorized extends GenericActionFailure {
  const new();
}

abstract interface class GenericActionRepository {
  Future<Result<List<GenericAction>>> perform({
    required RequestMethod method,
    required String endpoint,
    Map<String, Object?> body = const {},
  });
}
