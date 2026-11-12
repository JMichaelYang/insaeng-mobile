import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/ui/home/view_models/home_cubit.dart';

void main() {
  group(HomeCubit, () {
    test('initial state has a count of 0', () {
      expect(HomeCubit().state, const HomeState());
    });

    blocTest<HomeCubit, HomeState>(
      'increment emits the next count',
      build: HomeCubit.new,
      act: (cubit) => cubit
        ..increment()
        ..increment(),
      expect: () => const [HomeState(count: 1), HomeState(count: 2)],
    );
  });
}
