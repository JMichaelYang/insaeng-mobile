import 'package:dart_mappable/dart_mappable.dart';
import 'package:insaeng/data/services/generic_page_fixture_service.dart';
import 'package:insaeng/domain/models/generic_ui/generic_page.dart';
import 'package:insaeng/domain/repositories/generic_page_repository.dart';
import 'package:insaeng/domain/result.dart';

final class GenericPageRepositoryImpl implements GenericPageRepository {
  new(this._fixtures);

  final GenericPageFixtureService _fixtures;

  @override
  Future<Result<GenericPage>> fetch(String id, Map<String, String> params) async {
    try {
      final page = GenericPageMapper.fromMap(await _fixtures.fetchPage(id));
      return _hasValidIds(page) ? Result.ok(page) : const Result.err(GenericPageInvalid());
    } on GenericPageFixtureNotFoundException {
      return const Result.err(GenericPageNotFound());
    } on FormatException {
      return const Result.err(GenericPageInvalid());
    } on MapperException {
      return const Result.err(GenericPageInvalid());
    }
  }

  static bool _hasValidIds(GenericPage page) {
    final ids = <String>{};
    return page.nodes.every((node) => node.id.isNotEmpty && ids.add(node.id));
  }
}
