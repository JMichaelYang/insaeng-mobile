import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/ui/home/view_models/home_cubit.dart';
import 'package:insaeng/ui/home/widgets/home_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _MockHomeCubit extends MockCubit<HomeState> implements HomeCubit;

void main() {
  group(HomeScreen, () {
    late HomeCubit cubit;

    setUp(() {
      cubit = _MockHomeCubit();
      when(() => cubit.state).thenReturn(const HomeState(count: 3));
    });

    Widget buildSubject() =>
        BlocProvider.value(value: cubit, child: const HomeScreen());

    testWidgets('shows the localized title', (tester) async {
      await tester.pumpApp(buildSubject());
      expect(find.text('Insaeng'), findsOneWidget);

      await tester.pumpApp(buildSubject(), locale: const Locale('ko'));
      await tester.pumpAndSettle();
      expect(find.text('인생'), findsOneWidget);
    });

    testWidgets('shows the count from state', (tester) async {
      await tester.pumpApp(buildSubject());

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('tapping the button increments', (tester) async {
      await tester.pumpApp(buildSubject());

      await tester.tap(find.byType(FloatingActionButton));

      verify(() => cubit.increment()).called(1);
    });
  });
}
