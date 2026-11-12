part of 'home_cubit.dart';

@freezed
abstract class HomeState with _$HomeState {
  const factory({@Default(0) int count}) = _HomeState;
}
