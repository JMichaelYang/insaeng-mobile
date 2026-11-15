import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_page.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/domain/repositories/generic_page_repository.dart';
import 'package:insaeng/l10n/l10n.dart';
import 'package:insaeng/ui/generic/view_models/generic_cubit.dart';
import 'package:insaeng/ui/generic/widgets/generic_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _MockGenericCubit extends MockCubit<GenericState> implements GenericCubit;

const _page = GenericPage(
  id: 'home',
  root: ColumnNode(
    id: 'root',
    children: [
      AppBarNode(id: 'appBar', title: Literal('Counter')),
      TextNode(id: 'count', text: Literal('3')),
    ],
  ),
);

void main() {
  group(GenericScreen, () {
    late GenericCubit cubit;
    late StreamController<GenericEffect> effects;

    setUp(() {
      cubit = _MockGenericCubit();
      effects = StreamController<GenericEffect>.broadcast();
      when(() => cubit.effects).thenAnswer((_) => effects.stream);
      when(() => cubit.retry()).thenAnswer((_) async {});
    });

    tearDown(() => effects.close());

    Widget buildSubject() => BlocProvider.value(value: cubit, child: const GenericScreen());

    testWidgets('shows a progress indicator while loading', (tester) async {
      when(() => cubit.state).thenReturn(const GenericState());

      await tester.pumpApp(buildSubject());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders the root node as the body with no app bar of its own', (tester) async {
      when(() => cubit.state).thenReturn(const GenericState(status: GenericStatus.success, page: _page));

      await tester.pumpApp(buildSubject());

      expect(find.byKey(const ValueKey('root')), findsOneWidget);
      expect(find.text('Counter'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(tester.widget<Scaffold>(find.byType(Scaffold)).appBar, isNull);
    });

    testWidgets('shows a localized error that retries', (tester) async {
      when(() => cubit.state)
          .thenReturn(const GenericState(status: GenericStatus.failure, failure: GenericPageNotFound()));

      await tester.pumpApp(buildSubject());
      expect(find.text('Something went wrong loading this page.'), findsOneWidget);

      await tester.tap(find.text('Try again'));

      verify(() => cubit.retry()).called(1);
    });

    testWidgets('shows a snackbar for a message effect', (tester) async {
      when(() => cubit.state).thenReturn(const GenericState(status: GenericStatus.success, page: _page));
      await tester.pumpApp(buildSubject());

      effects.add(const ShowMessageEffect(text: 'Saved'));
      await tester.pump();

      expect(find.widgetWithText(SnackBar, 'Saved'), findsOneWidget);
    });

    group('navigation effects', () {
      late GoRouter router;

      setUp(() {
        when(() => cubit.state).thenReturn(const GenericState(status: GenericStatus.success, page: _page));
        router = GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, _) => buildSubject()),
            GoRoute(path: '/p/:pageId', builder: (_, state) => Text('page ${state.uri}')),
          ],
        );
      });

      tearDown(() => router.dispose());

      Future<void> pumpRouter(WidgetTester tester) => tester.pumpWidget(
        MaterialApp.router(
          localizationsDelegates: localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );

      testWidgets('navigate pushes the page with its params', (tester) async {
        await pumpRouter(tester);

        effects.add(const NavigateEffect(pageId: 'detail', params: {'id': '7'}));
        await tester.pumpAndSettle();

        expect(find.text('page /p/detail?id=7'), findsOneWidget);
        expect(router.canPop(), isTrue);
      });

      testWidgets('navigate with replace replaces the current page', (tester) async {
        await pumpRouter(tester);

        effects.add(const NavigateEffect(pageId: 'detail', replace: true));
        await tester.pumpAndSettle();

        expect(find.text('page /p/detail'), findsOneWidget);
        expect(router.canPop(), isFalse);
      });

      testWidgets('back pops the current page', (tester) async {
        await pumpRouter(tester);
        unawaited(router.push<void>('/p/detail'));
        await tester.pumpAndSettle();
        expect(find.text('page /p/detail'), findsOneWidget);

        effects.add(const BackEffect());
        await tester.pumpAndSettle();

        expect(find.text('page /p/detail'), findsNothing);
        expect(find.byKey(const ValueKey('root')), findsOneWidget);
      });

      testWidgets('back does nothing on the first page', (tester) async {
        await pumpRouter(tester);

        effects.add(const BackEffect());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('root')), findsOneWidget);
      });
    });
  });
}
