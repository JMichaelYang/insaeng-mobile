import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:insaeng/app.dart';
import 'package:insaeng/config/dependencies.dart';
import 'package:insaeng/config/flavor.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_page.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/domain/repositories/generic_page_repository.dart';
import 'package:insaeng/domain/result.dart';
import 'package:insaeng/routing/router.dart';
import 'package:insaeng/routing/routes.dart';
import 'package:insaeng/ui/generic/widgets/generic_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockGenericPageRepository extends Mock implements GenericPageRepository;

void main() {
  group(router, () {
    group('with the dev fixtures', () {
      setUp(() => configureDependencies(Flavor.dev));

      tearDown(getIt.reset);

      testWidgets('opens the home page and runs its counter', (tester) async {
        await tester.runAsync(() => tester.pumpWidget(App(router: getIt<GoRouter>())));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pumpAndSettle();

        expect(find.byType(GenericScreen), findsOneWidget);
        expect(find.text('Insaeng'), findsOneWidget);
        expect(find.text('0'), findsOneWidget);

        await tester.tap(find.text('Add'));
        await tester.pump();

        expect(find.text('1'), findsOneWidget);
      });
    });

    group('page routes', () {
      late GetIt locator;
      late GenericPageRepository repository;
      late GoRouter subject;

      setUp(() {
        repository = _MockGenericPageRepository();
        locator = GetIt.asNewInstance()..registerSingleton<GenericPageRepository>(repository);
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

        expect(find.text('page home'), findsOneWidget);
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
