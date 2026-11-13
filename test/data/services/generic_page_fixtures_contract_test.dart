import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/data/repositories/generic_page_repository_impl.dart';
import 'package:insaeng/data/services/generic_page_fixture_service.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_page.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/domain/result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('generic page fixtures', () {
    late List<String> ids;

    setUpAll(() async {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final pattern = RegExp('^${GenericPageFixtureService.directory}/(.+)\\.json\$');
      ids = [for (final path in manifest.listAssets()) ?pattern.firstMatch(path)?.group(1)];
    });

    test('include home', () => expect(ids, contains('home')));

    test('decode with no unknown nodes or actions', () async {
      final repository = GenericPageRepositoryImpl(GenericPageFixtureService(rootBundle));

      for (final id in ids) {
        final result = await repository.fetch(id, const {});

        expect(result, isA<Ok<GenericPage>>(), reason: id);
        final page = (result as Ok<GenericPage>).value;
        expect(page.id, id, reason: id);
        expect(page.nodes.whereType<UnknownNode>(), isEmpty, reason: id);
        expect(page.actions.whereType<UnknownAction>(), isEmpty, reason: id);
      }
    });
  });
}
