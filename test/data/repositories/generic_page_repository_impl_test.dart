import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/data/repositories/generic_page_repository_impl.dart';
import 'package:insaeng/data/services/generic_page_fixture_service.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_page.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/domain/repositories/generic_page_repository.dart';
import 'package:insaeng/domain/result.dart';
import 'package:mocktail/mocktail.dart';

class _MockGenericPageFixtureService extends Mock implements GenericPageFixtureService;

Map<String, Object?> _page(List<Map<String, Object?>> children) => {
  'id': 'home',
  'root': {'type': 'column', 'id': 'root', 'children': children},
};

void main() {
  group(GenericPageRepositoryImpl, () {
    late GenericPageFixtureService fixtures;
    late GenericPageRepository repository;

    setUp(() {
      fixtures = _MockGenericPageFixtureService();
      repository = GenericPageRepositoryImpl(fixtures);
    });

    void stub(Map<String, Object?> json) => when(() => fixtures.fetchPage('home')).thenAnswer((_) async => json);

    test('fetch returns the decoded page', () async {
      stub({
        ..._page([
          {'type': 'text', 'id': 'count', 'text': 'Zero'},
        ]),
        'state': {'count': 0},
      });

      expect(
        await repository.fetch('home', const {'tab': 'all'}),
        Result.ok(
          GenericPage(
            id: 'home',
            state: GenericValues(const {'count': 0}),
            root: const ColumnNode(
              id: 'root',
              children: [TextNode(id: 'count', text: Literal('Zero'))],
            ),
          ),
        ),
      );
    });

    test('fetch returns not found when there is no fixture', () async {
      when(() => fixtures.fetchPage('home')).thenThrow(const GenericPageFixtureNotFoundException('home'));

      expect(await repository.fetch('home', const {}), const Result<GenericPage>.err(GenericPageNotFound()));
    });

    test('fetch returns invalid for malformed JSON', () async {
      when(() => fixtures.fetchPage('home')).thenThrow(const FormatException());

      expect(await repository.fetch('home', const {}), const Result<GenericPage>.err(GenericPageInvalid()));
    });

    test('fetch returns invalid when the page does not decode', () async {
      stub({'id': 'home'});

      expect(await repository.fetch('home', const {}), const Result<GenericPage>.err(GenericPageInvalid()));
    });

    test('fetch returns invalid when a node has no id', () async {
      stub(
        _page([
          {'type': 'text', 'text': 'Zero'},
        ]),
      );

      expect(await repository.fetch('home', const {}), const Result<GenericPage>.err(GenericPageInvalid()));
    });

    test('fetch returns invalid when a node has an empty id', () async {
      stub(
        _page([
          {'type': 'text', 'id': '', 'text': 'Zero'},
        ]),
      );

      expect(await repository.fetch('home', const {}), const Result<GenericPage>.err(GenericPageInvalid()));
    });

    test('fetch returns invalid when two nodes share an id', () async {
      stub(
        _page([
          {'type': 'text', 'id': 'count', 'text': 'Zero'},
          {'type': 'text', 'id': 'count', 'text': 'One'},
        ]),
      );

      expect(await repository.fetch('home', const {}), const Result<GenericPage>.err(GenericPageInvalid()));
    });

    test('fetch returns invalid when a fallback reuses an id', () async {
      stub(
        _page([
          {
            'type': 'carousel',
            'id': 'hero',
            'fallback': {'type': 'text', 'id': 'root', 'text': 'Featured'},
          },
        ]),
      );

      expect(await repository.fetch('home', const {}), const Result<GenericPage>.err(GenericPageInvalid()));
    });
  });
}
