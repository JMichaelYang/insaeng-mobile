import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_page.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/domain/repositories/generic_action_repository.dart';
import 'package:insaeng/domain/repositories/generic_page_repository.dart';
import 'package:insaeng/l10n/l10n.dart';
import 'package:insaeng/ui/generic/items/app_bar_item.dart';
import 'package:insaeng/ui/generic/items/checkbox_tile_item.dart';
import 'package:insaeng/ui/generic/items/column_item.dart';
import 'package:insaeng/ui/generic/items/expanded_item.dart';
import 'package:insaeng/ui/generic/items/scroll_item.dart';
import 'package:insaeng/ui/generic/items/text_item.dart';
import 'package:insaeng/ui/generic/view_models/generic_cubit.dart';
import 'package:insaeng/ui/generic/widgets/generic_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../../helpers/pump_app.dart';

class _MockGenericCubit extends MockCubit<GenericState> implements GenericCubit;

class _MockGenericPageRepository extends Mock implements GenericPageRepository;

class _MockGenericActionRepository extends Mock implements GenericActionRepository;

class _MockUrlLauncher extends Mock with MockPlatformInterfaceMixin implements UrlLauncherPlatform;

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

    group('open url effects', () {
      late UrlLauncherPlatform launcher;
      late UrlLauncherPlatform original;

      setUpAll(() => registerFallbackValue(const LaunchOptions()));

      setUp(() {
        when(() => cubit.state).thenReturn(const GenericState(status: GenericStatus.success, page: _page));
        original = UrlLauncherPlatform.instance;
        launcher = _MockUrlLauncher();
        UrlLauncherPlatform.instance = launcher;
        when(() => launcher.launchUrl(any(), any())).thenAnswer((_) async => true);
      });

      tearDown(() => UrlLauncherPlatform.instance = original);

      testWidgets('opens the url in an external application', (tester) async {
        await tester.pumpApp(buildSubject());

        effects.add(const OpenUrlEffect(url: 'https://claude.ai/new'));
        await tester.pump();

        final options =
            verify(() => launcher.launchUrl('https://claude.ai/new', captureAny())).captured.single as LaunchOptions;
        expect(options.mode, PreferredLaunchMode.externalApplication);
      });

      testWidgets('skips a url that does not parse', (tester) async {
        await tester.pumpApp(buildSubject());

        effects.add(const OpenUrlEffect(url: 'http://[::1'));
        await tester.pump();

        verifyNever(() => launcher.launchUrl(any(), any()));
      });

      testWidgets('ignores a url no app can open', (tester) async {
        when(() => launcher.launchUrl(any(), any())).thenThrow(PlatformException(code: 'ACTIVITY_NOT_FOUND'));
        await tester.pumpApp(buildSubject());

        effects.add(const OpenUrlEffect(url: 'insaeng-unknown://x'));
        await tester.pump();

        verify(() => launcher.launchUrl('insaeng-unknown://x', any())).called(1);
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('root')), findsOneWidget);
      });
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

    group('on a state change', () {
      const rows = 100;
      late GenericCubit realCubit;

      setUp(() {
        realCubit = GenericCubit.widget(
          _MockGenericPageRepository(),
          _MockGenericActionRepository(),
          pageId: 'list',
          page: _listPage(rows),
          values: GenericValues({
            'todos': [
              for (var i = 0; i < rows; i++) {'done': false},
            ],
            'counts': [for (var i = 0; i < rows; i++) i],
          }),
        );
      });

      tearDown(() => realCubit.close());

      Future<List<String>> rebuiltItems(WidgetTester tester, UpdateStateAction action) async {
        await tester.pumpApp(BlocProvider.value(value: realCubit, child: const GenericScreen()));
        await tester.pumpAndSettle();
        final rebuilt = <String>[];
        debugOnRebuildDirtyWidget = (element, _) {
          if (_itemId(element.widget) case final id?) rebuilt.add(id);
        };
        try {
          await realCubit.dispatch([action]);
          await tester.pump();
        } finally {
          debugOnRebuildDirtyWidget = null;
        }
        return rebuilt;
      }

      testWidgets('rebuilds only the text bound to the changed path', (tester) async {
        final rebuilt = await rebuiltItems(tester, const UpdateStateAction(path: 'counts.5', value: Literal(999)));

        expect(rebuilt, ['count5']);
        expect(find.text('999'), findsOneWidget);
      });

      testWidgets('rebuilds only the checkbox tile bound to the changed path', (tester) async {
        final rebuilt = await rebuiltItems(tester, const UpdateStateAction(path: 'todos.5.done', value: Literal(true)));

        expect(rebuilt, ['todo5']);
      });

      testWidgets('rebuilds no items when an unbound path changes', (tester) async {
        final rebuilt = await rebuiltItems(tester, const UpdateStateAction(path: 'unbound', value: Literal(1)));

        expect(rebuilt, isEmpty);
      });
    });
  });
}

GenericPage _listPage(int rows) => GenericPage(
  id: 'list',
  root: ColumnNode(
    id: 'root',
    children: [
      const AppBarNode(id: 'appBar', title: Literal('List')),
      ExpandedNode(
        id: 'body',
        child: ScrollNode(
          id: 'scroll',
          child: ColumnNode(
            id: 'rows',
            children: [
              for (var i = 0; i < rows; i++) ...[
                TextNode(id: 'label$i', text: Literal('Row $i')),
                CheckboxTileNode(id: 'todo$i', title: Literal('Todo $i'), bind: 'todos.$i.done'),
                TextNode(id: 'count$i', text: Binding('counts.$i')),
              ],
            ],
          ),
        ),
      ),
    ],
  ),
);

String? _itemId(Widget widget) => switch (widget) {
  ColumnItem(:final node) => node.id,
  ExpandedItem(:final node) => node.id,
  ScrollItem(:final node) => node.id,
  AppBarItem(:final node) => node.id,
  TextItem(:final node) => node.id,
  CheckboxTileItem(:final node) => node.id,
  _ => null,
};
