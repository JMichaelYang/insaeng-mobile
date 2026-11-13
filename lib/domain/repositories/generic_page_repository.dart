import 'package:insaeng/domain/models/generic_ui/generic_page.dart';
import 'package:insaeng/domain/result.dart';

sealed class GenericPageFailure extends Failure {
  const new();
}

final class GenericPageNotFound extends GenericPageFailure {
  const new();
}

final class GenericPageOffline extends GenericPageFailure {
  const new();
}

final class GenericPageServerError extends GenericPageFailure {
  const new();
}

final class GenericPageInvalid extends GenericPageFailure {
  const new();
}

abstract interface class GenericPageRepository {
  Future<Result<GenericPage>> fetch(String id, Map<String, String> params);
}
