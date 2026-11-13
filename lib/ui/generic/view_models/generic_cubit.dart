import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/repositories/generic_page_repository.dart';
import 'package:insaeng/domain/result.dart';
import 'package:insaeng/ui/generic/view_models/generic_state.dart';

export 'package:insaeng/ui/generic/view_models/generic_state.dart';

class GenericCubit extends Cubit<GenericState> {
  new(this._repository, {required this.pageId, this.params = const {}}) : super(const GenericState());

  final GenericPageRepository _repository;
  final String pageId;
  final Map<String, String> params;

  Future<void> load() async {
    final result = await _repository.fetch(pageId, params);
    if (isClosed) return;
    switch (result) {
      case Ok(value: final page):
        emit(state.copyWith(status: GenericStatus.success, page: page, values: page.initialState, failure: null));
        await dispatch(page.onLoad);
      case Err(:final failure):
        emit(state.copyWith(status: GenericStatus.failure, failure: failure));
    }
  }

  Future<void> dispatch(List<GenericAction> actions) async {
    for (final action in actions) {
      if (isClosed || !await _run(action)) return;
    }
  }

  Future<bool> _run(GenericAction action) async => switch (action) {
    final UpdateStateAction action => _updateState(action),
    NavigateAction() ||
    BackAction() ||
    ReloadAction() ||
    ShowMessageAction() ||
    RequestAction() ||
    UnknownAction() => true,
  };

  bool _updateState(UpdateStateAction action) {
    final values = state.values;
    final op = action.op.resolve(values) ?? UpdateOp.set;
    switch (values.update(action.path, op, action.value?.resolve(values))) {
      case Ok(value: final updated):
        emit(state.copyWith(values: updated));
        return true;
      case Err():
        return false;
    }
  }
}
