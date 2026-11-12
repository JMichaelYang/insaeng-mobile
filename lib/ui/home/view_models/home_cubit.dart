import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insaeng/ui/home/view_models/home_state.dart';

export 'package:insaeng/ui/home/view_models/home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  new() : super(const HomeState());

  void increment() => emit(state.copyWith(count: state.count + 1));
}
