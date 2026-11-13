import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/repositories/generic_page_repository.dart';
import 'package:insaeng/domain/result.dart';
import 'package:insaeng/ui/generic/view_models/generic_effect.dart';
import 'package:insaeng/ui/generic/view_models/generic_state.dart';

export 'package:insaeng/ui/generic/view_models/generic_effect.dart';
export 'package:insaeng/ui/generic/view_models/generic_state.dart';

class GenericCubit extends Cubit<GenericState> {
  new(this._repository, {required this.pageId, this.params = const {}}) : super(const GenericState());

  final GenericPageRepository _repository;
  final String pageId;
  final Map<String, String> params;
  final _effects = StreamController<GenericEffect>.broadcast();

  Stream<GenericEffect> get effects => _effects.stream;

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

  Future<void> retry() async {
    emit(state.copyWith(status: GenericStatus.loading, failure: null));
    await load();
  }

  Future<void> dispatch(List<GenericAction> actions) async {
    for (final action in actions) {
      if (isClosed || !await _run(action)) return;
    }
  }

  Future<bool> _run(GenericAction action) async => switch (action) {
    final UpdateStateAction action => _updateState(action),
    ReloadAction() => await _reload(),
    final NavigateAction action => _navigate(action),
    BackAction() => _emitEffect(const BackEffect()),
    final ShowMessageAction action => _showMessage(action),
    RequestAction() || UnknownAction() => true,
  };

  Future<bool> _reload() async {
    final result = await _repository.fetch(pageId, params);
    if (isClosed) return false;
    switch (result) {
      case Ok(value: final page):
        emit(state.copyWith(page: page, values: page.state ?? state.values));
        return true;
      case Err():
        return false;
    }
  }

  bool _navigate(NavigateAction action) {
    final values = state.values;
    final pageId = action.pageId.resolve(values);
    if (pageId == null) return true;
    return _emitEffect(
      NavigateEffect(
        pageId: pageId,
        params: action.params.resolve(values) ?? const {},
        replace: action.replace.resolve(values) ?? false,
      ),
    );
  }

  bool _showMessage(ShowMessageAction action) {
    final text = action.text.resolve(state.values);
    if (text == null) return true;
    return _emitEffect(ShowMessageEffect(text: text));
  }

  bool _emitEffect(GenericEffect effect) {
    _effects.add(effect);
    return true;
  }

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

  @override
  Future<void> close() async {
    await _effects.close();
    await super.close();
  }
}
