import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/text_item.dart';
import 'package:insaeng/ui/generic/view_models/generic_cubit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _MockGenericCubit extends MockCubit<GenericState> implements GenericCubit;

void main() {
  group(TextItem, () {
    late GenericCubit cubit;

    setUp(() => cubit = _MockGenericCubit());

    GenericState stateWith(Map<String, Object?> values) =>
        GenericState(status: GenericStatus.success, values: GenericValues(values));

    Future<void> pumpItem(WidgetTester tester, TextNode node, {Map<String, Object?> values = const {}}) {
      when(() => cubit.state).thenReturn(stateWith(values));
      return tester.pumpApp(
        BlocProvider.value(
          value: cubit,
          child: Scaffold(body: TextItem(node: node)),
        ),
      );
    }

    TextStyle? styleOf(WidgetTester tester, String text) => tester.widget<Text>(find.text(text)).style;

    TextTheme textTheme(WidgetTester tester) => Theme.of(tester.element(find.byType(TextItem))).textTheme;

    testWidgets('shows a literal text in bodyMedium by default', (tester) async {
      await pumpItem(tester, const TextNode(id: 'text', text: Literal('Hello')));

      expect(find.text('Hello'), findsOneWidget);
      expect(styleOf(tester, 'Hello'), textTheme(tester).bodyMedium);
    });

    testWidgets('shows a bound number as text', (tester) async {
      await pumpItem(
        tester,
        const TextNode(id: 'count', text: Binding('count')),
        values: {'count': 3},
      );

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows the fallback when the path is missing', (tester) async {
      await pumpItem(
        tester,
        const TextNode(
          id: 'name',
          text: Binding('name', fallback: 'Guest'),
        ),
      );

      expect(find.text('Guest'), findsOneWidget);
    });

    testWidgets('shows empty text when the path is missing without a fallback', (tester) async {
      await pumpItem(tester, const TextNode(id: 'name', text: Binding('name')));

      expect(tester.widget<Text>(find.byType(Text)).data, isEmpty);
    });

    for (final token in TextStyleToken.values) {
      testWidgets('maps the ${token.name} style to the text theme', (tester) async {
        await pumpItem(tester, TextNode(id: 'text', text: const Literal('Hello'), style: Literal(token)));

        final theme = textTheme(tester);
        final expected = {
          TextStyleToken.displayLarge: theme.displayLarge,
          TextStyleToken.displayMedium: theme.displayMedium,
          TextStyleToken.displaySmall: theme.displaySmall,
          TextStyleToken.headlineLarge: theme.headlineLarge,
          TextStyleToken.headlineMedium: theme.headlineMedium,
          TextStyleToken.headlineSmall: theme.headlineSmall,
          TextStyleToken.titleLarge: theme.titleLarge,
          TextStyleToken.titleMedium: theme.titleMedium,
          TextStyleToken.titleSmall: theme.titleSmall,
          TextStyleToken.bodyLarge: theme.bodyLarge,
          TextStyleToken.bodyMedium: theme.bodyMedium,
          TextStyleToken.bodySmall: theme.bodySmall,
          TextStyleToken.labelLarge: theme.labelLarge,
          TextStyleToken.labelMedium: theme.labelMedium,
          TextStyleToken.labelSmall: theme.labelSmall,
        }[token];
        expect(styleOf(tester, 'Hello'), expected);
      });
    }

    testWidgets('updates when the bound value changes', (tester) async {
      whenListen(cubit, Stream.value(stateWith({'count': 1})), initialState: stateWith({'count': 0}));
      await tester.pumpApp(
        BlocProvider.value(
          value: cubit,
          child: const Scaffold(
            body: TextItem(
              node: TextNode(id: 'count', text: Binding('count')),
            ),
          ),
        ),
      );
      expect(find.text('0'), findsOneWidget);

      await tester.pump();

      expect(find.text('1'), findsOneWidget);
    });
  });
}
