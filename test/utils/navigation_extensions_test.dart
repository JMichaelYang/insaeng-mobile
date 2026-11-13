import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:insaeng/utils/navigation_extensions.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('NavigationExtensions', () {
    late BuildContext context;
    late GoRouter router;

    setUp(() {
      Widget page(BuildContext c, String label) {
        context = c;
        return Text(label);
      }

      router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (c, _) => page(c, 'first')),
          GoRoute(path: '/second', builder: (c, _) => page(c, 'second')),
        ],
      );
    });

    tearDown(() => router.dispose());

    Future<void> pumpRouter(WidgetTester tester) => tester.pumpWidget(MaterialApp.router(routerConfig: router));

    testWidgets('goTo replaces the current location', (tester) async {
      await pumpRouter(tester);

      context.goTo('/second');
      await tester.pumpAndSettle();

      expect(find.text('second'), findsOneWidget);
      expect(router.canPop(), isFalse);
    });

    testWidgets('replaceWith swaps the top page', (tester) async {
      await pumpRouter(tester);

      unawaited(context.replaceWith<void>('/second'));
      await tester.pumpAndSettle();

      expect(find.text('second'), findsOneWidget);
      expect(context.canGoBack, isFalse);
    });

    testWidgets('canGoBack is true only above the first page', (tester) async {
      await pumpRouter(tester);
      expect(context.canGoBack, isFalse);

      unawaited(context.pushTo<void>('/second'));
      await tester.pumpAndSettle();

      expect(context.canGoBack, isTrue);
    });

    testWidgets('pushTo resolves with the result passed to back', (tester) async {
      await pumpRouter(tester);

      final result = context.pushTo<int>('/second');
      await tester.pumpAndSettle();
      expect(find.text('second'), findsOneWidget);

      context.back(7);
      await tester.pumpAndSettle();

      expect(find.text('first'), findsOneWidget);
      expect(await result, 7);
    });
  });
}
