import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:insaeng/app.dart';
import 'package:insaeng/config/dependencies.dart';
import 'package:insaeng/config/flavor.dart';
import 'package:insaeng/data/repositories/generic_notion_page_repository_impl.dart';
import 'package:insaeng/data/repositories/my_day_page_mapper.dart';
import 'package:insaeng/data/services/secure_storage_service.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_page.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/domain/repositories/generic_action_repository.dart';
import 'package:insaeng/domain/repositories/generic_page_repository.dart';
import 'package:insaeng/domain/result.dart';
import 'package:insaeng/routing/router.dart';
import 'package:insaeng/routing/routes.dart';
import 'package:insaeng/ui/generic/widgets/generic_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockGenericActionRepository extends Mock implements GenericActionRepository;

class _MockGenericPageRepository extends Mock implements GenericPageRepository;

void main() {
  group(router, () {
    group('with the app dependencies', () {
      setUp(() {
        FlutterSecureStorage.setMockInitialValues({});
        configureDependencies(Flavor.dev);
      });

      tearDown(getIt.reset);

      testWidgets('opens on the Notion connect page and reloads after saving a token', (tester) async {
        await tester.pumpWidget(App(router: getIt<GoRouter>()));
        await tester.pumpAndSettle();

        expect(find.byType(GenericScreen), findsOneWidget);
        expect(find.text(GenericNotionPageRepositoryImpl.connectTitle), findsOneWidget);

        await tester.enterText(find.byType(TextField), '  secret  ');
        await tester.tap(find.text(GenericNotionPageRepositoryImpl.connectLabel));
        await tester.pumpAndSettle();

        expect(find.text(GenericNotionPageRepositoryImpl.connectTitle), findsNothing);
        expect(find.text(MyDayPageMapper.emptyText), findsOneWidget);
        expect(await getIt<SecureStorageService>().read(SecureStorageService.notionTokenKey), 'secret');
      });
    });

    group('page routes', () {
      late GetIt locator;
      late GenericPageRepository repository;
      late GoRouter subject;

      setUp(() {
        repository = _MockGenericPageRepository();
        locator = GetIt.asNewInstance()
          ..registerSingleton<GenericActionRepository>(_MockGenericActionRepository())
          ..registerSingleton<GenericPageRepository>(repository);
        when(() => repository.fetch(any(), any())).thenAnswer(
          (invocation) async => Result.ok(
            GenericPage(
              id: invocation.positionalArguments.first as String,
              root: TextNode(id: 'title', text: Literal('page ${invocation.positionalArguments.first}')),
            ),
          ),
        );
        subject = router(locator);
      });

      tearDown(() => subject.dispose());

      testWidgets('loads the home page at the root', (tester) async {
        await tester.pumpWidget(App(router: subject));
        await tester.pumpAndSettle();

        expect(find.text('page ${Routes.homePageId}'), findsOneWidget);
        verify(() => repository.fetch(Routes.homePageId, const {})).called(1);
      });

      testWidgets('loads a page by id with its query params', (tester) async {
        await tester.pumpWidget(App(router: subject));
        await tester.pumpAndSettle();

        subject.go(Routes.pageLocation('detail', const {'id': '7'}));
        await tester.pumpAndSettle();

        expect(find.text('page detail'), findsOneWidget);
        verify(() => repository.fetch('detail', const {'id': '7'})).called(1);
      });
    });
  });
}
