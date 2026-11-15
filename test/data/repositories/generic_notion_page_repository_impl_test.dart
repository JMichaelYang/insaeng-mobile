import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/data/repositories/generic_notion_action_repository_impl.dart';
import 'package:insaeng/data/repositories/generic_notion_page_repository_impl.dart';
import 'package:insaeng/data/repositories/my_day_page_mapper.dart';
import 'package:insaeng/data/services/secure_storage_service.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/bindable_json.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_page.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/domain/repositories/generic_page_repository.dart';
import 'package:insaeng/domain/result.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorageService extends Mock implements SecureStorageService;

GenericPage _page(Result<GenericPage> result) => switch (result) {
  Ok(value: final page) => page,
  Err(:final failure) => throw TestFailure('Expected a page, got $failure'),
};

void main() {
  group(GenericNotionPageRepositoryImpl, () {
    late SecureStorageService storage;
    late GenericPageRepository repository;

    setUp(() {
      storage = _MockSecureStorageService();
      repository = GenericNotionPageRepositoryImpl(storage);
    });

    group(MyDayPageMapper.pageId, () {
      Future<Result<GenericPage>> fetch() => repository.fetch(MyDayPageMapper.pageId, const {});

      void stub({String? token = 'secret', String? dataSourceId = 'agenda'}) {
        when(() => storage.read(SecureStorageService.notionTokenKey)).thenAnswer((_) async => token);
        when(() => storage.read(SecureStorageService.notionDataSourceIdKey)).thenAnswer((_) async => dataSourceId);
      }

      for (final (description, value) in [('missing', null), ('empty', '')]) {
        test('returns the connect page when the token is $description', () async {
          stub(token: value);

          expect(await fetch(), Result<GenericPage>.ok(GenericNotionPageRepositoryImpl.connectPage));
        });

        test('returns the connect page when the data source id is $description', () async {
          stub(dataSourceId: value);

          expect(await fetch(), Result<GenericPage>.ok(GenericNotionPageRepositoryImpl.connectPage));
        });
      }

      test('returns the My Day page when a token and data source id are stored', () async {
        stub();

        final page = _page(await fetch());

        expect(page.id, MyDayPageMapper.pageId);
        expect(page.nodes.whereType<TextFieldNode>(), isEmpty);
        expect(page.nodes.whereType<TextNode>().single.text, const Literal(MyDayPageMapper.emptyText));
      });

      test('returns server error when storage fails', () async {
        when(() => storage.read(any())).thenThrow(PlatformException(code: 'error'));

        expect(await fetch(), const Result<GenericPage>.err(GenericPageServerError()));
      });
    });

    test('returns not found for other pages', () async {
      expect(await repository.fetch('home', const {}), const Result<GenericPage>.err(GenericPageNotFound()));
      verifyNever(() => storage.read(any()));
    });

    group('connectPage', () {
      final page = GenericNotionPageRepositoryImpl.connectPage;

      test('has unique node ids', () {
        final ids = [for (final node in page.nodes) node.id];

        expect(ids.toSet(), hasLength(ids.length));
      });

      test('starts with empty fields and no save in progress', () {
        expect(
          page.state,
          GenericValues(const {
            'notion': {'token': '', 'dataSourceId': ''},
            'saving': false,
          }),
        );
      });

      test('shows the My Day app bar', () {
        expect(page.nodes.whereType<AppBarNode>().single.title, const Literal(MyDayPageMapper.title));
      });

      test('binds a secure token field and a plain data source id field', () {
        final fields = {for (final field in page.nodes.whereType<TextFieldNode>()) field.bind: field.secure};

        expect(fields, const {'notion.token': Literal(true), 'notion.dataSourceId': Literal(false)});
      });

      test('saves both fields through the connection endpoint', () {
        final button = page.nodes.whereType<ButtonNode>().single;

        expect(button.loading, const Binding('saving', fallback: false));
        expect(button.onTap, const [
          UpdateStateAction(path: 'saving', value: Literal(true)),
          RequestAction(
            method: Literal(RequestMethod.put),
            endpoint: Literal(GenericNotionActionRepositoryImpl.connectionEndpoint),
            body: JsonObject({
              'token': JsonBinding(Binding('notion.token')),
              'dataSourceId': JsonBinding(Binding('notion.dataSourceId')),
            }),
            onError: [ShowMessageAction(text: Literal(GenericNotionPageRepositoryImpl.connectErrorText))],
            onComplete: [UpdateStateAction(path: 'saving', value: Literal(false))],
          ),
        ]);
      });
    });
  });
}
