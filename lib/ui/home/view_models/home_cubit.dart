import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_cubit.freezed.dart';
part 'home_state.dart';

/// View model for the Home screen.
///
/// Reference feature: copy this shape (Cubit + freezed state, registered in
/// `config/dependencies.dart`, provided by the route) for new features.
class HomeCubit extends Cubit<HomeState> {
  new() : super(const HomeState());

  void increment() => emit(state.copyWith(count: state.count + 1));
}
