import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/repositories/generic_action_repository.dart';
import 'package:insaeng/domain/repositories/generic_page_repository.dart';
import 'package:insaeng/domain/result.dart';
import 'package:insaeng/ui/generic/view_models/generic_effect.dart';
import 'package:insaeng/ui/generic/view_models/generic_state.dart';

export 'package:insaeng/ui/generic/view_models/generic_effect.dart';
export 'package:insaeng/ui/generic/view_models/generic_state.dart';

class GenericCubit extends Cubit<GenericState> {
  new(this._pages, this._actions, {required this.pageId, this.params = const {}}) : super(const GenericState());

  final GenericPageRepository _pages;
  final GenericActionRepository _actions;
  final String pageId;
  final Map<String, String> params;
  final _effects = StreamController<GenericEffect>.broadcast();

  Stream<GenericEffect> get effects => _effects.stream;

  Future<void> load() async {
    final result = await _pages.fetch(pageId, params);
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

  Future<void> dispatch(List<GenericAction> actions) => _runAll(actions);

  Future<bool> _runAll(List<GenericAction> actions) async {
    for (final action in actions) {
      if (isClosed || !await _run(action)) return false;
    }
    return true;
  }

  Future<bool> _run(GenericAction action) async => switch (action) {
    final UpdateStateAction action => _updateState(action),
    ReloadAction() => await _reload(),
    final NavigateAction action => _navigate(action),
    BackAction() => _emitEffect(const BackEffect()),
    final ShowMessageAction action => _showMessage(action),
    final RequestAction action => await _request(action),
    UnknownAction() => true,
  };

  Future<bool> _request(RequestAction action) async {
    final values = state.values;
    final endpoint = action.endpoint.resolve(values);
    if (endpoint == null) return true;
    final result = await _actions.perform(
      method: action.method.resolve(values) ?? RequestMethod.post,
      endpoint: endpoint,
      body: switch (action.body?.resolve(values)) {
        final Map<String, Object?> body => body,
        _ => const {},
      },
    );
    if (isClosed) return false;
    switch (result) {
      case Ok(value: final actions):
        return await _runAll(actions);
      case Err():
        await _runAll(action.onError);
        return false;
    }
  }

  Future<bool> _reload() async {
    final result = await _pages.fetch(pageId, params);
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
