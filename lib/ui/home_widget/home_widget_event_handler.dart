import 'dart:async';

import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/domain/models/home_widget/widget_snapshot_resolver.dart';
import 'package:insaeng/domain/repositories/generic_action_repository.dart';
import 'package:insaeng/domain/repositories/generic_page_repository.dart';
import 'package:insaeng/domain/repositories/widget_snapshot_repository.dart';
import 'package:insaeng/domain/result.dart';
import 'package:insaeng/ui/generic/view_models/generic_cubit.dart';

class HomeWidgetEventHandler {
  new(this._pages, this._actions, this._snapshots);

  static const pageKey = 'page';
  static const nodeKey = 'node';
  static const eventKey = 'event';

  final GenericPageRepository _pages;
  final GenericActionRepository _actions;
  final WidgetSnapshotRepository _snapshots;
  final _sessions = <String, Future<_PageSession?>>{};
  final _users = <String, int>{};

  Future<void> handle(Uri? uri) async {
    final params = uri?.queryParameters ?? const <String, String>{};
    if (params case {pageKey: final pageId, nodeKey: final nodeId, eventKey: final event}) {
      final pending = _sessions[pageId] ??= _open(pageId);
      _users.update(pageId, (count) => count + 1, ifAbsent: () => 1);
      try {
        await (await pending)?.run(nodeId, event);
      } finally {
        if (_users.update(pageId, (count) => count - 1) == 0) {
          _users.remove(pageId);
          await (await _sessions.remove(pageId))?.close();
        }
      }
    }
  }

  Future<_PageSession?> _open(String pageId) async => switch (await _snapshots.load(pageId)) {
    Ok(value: (:final page, :final values)) => _PageSession(
      GenericCubit.widget(_pages, _actions, pageId: pageId, page: page, values: values),
      _snapshots,
    ),
    Err() => null,
  };
}

final class _PageSession {
  new(this._cubit, this._snapshots) {
    _subscription = _cubit.stream.listen(_render);
  }

  final GenericCubit _cubit;
  final WidgetSnapshotRepository _snapshots;
  late final StreamSubscription<GenericState> _subscription;
  Future<void> _rendered = Future.value();
  Future<void>? _reloading;
  var _running = 0;

  Future<void> run(String nodeId, String event) async {
    for (var reloading = _reloading; reloading != null; reloading = _reloading) {
      await reloading;
    }
    final actions = _actionsFor(nodeId, event);
    if (actions == null) return;
    _running++;
    try {
      await _cubit.dispatch(actions);
    } finally {
      _running--;
    }
    if (_running == 0) await _reload();
    await _rendered;
  }

  Future<void> _reload() async {
    final reloading = _reloading = _cubit.dispatch(const [ReloadAction()]);
    try {
      await reloading;
    } finally {
      if (identical(_reloading, reloading)) _reloading = null;
    }
  }

  Future<void> close() async {
    await _rendered;
    await _subscription.cancel();
    await _cubit.close();
  }

  List<GenericAction>? _actionsFor(String nodeId, String event) {
    final GenericState(:page, :values) = _cubit.state;
    final node = page?.nodes.where((node) => node.id == nodeId).firstOrNull;
    return switch ((node, event)) {
      (CheckboxTileNode(:final busy), 'onChanged') when _running > 0 && (busy.resolve(values) ?? false) => null,
      (CheckboxTileNode(:final bind, :final onChanged), 'onChanged') => [
        UpdateStateAction(path: bind, value: Literal(!(Binding<bool>(bind).resolve(values) ?? false))),
        ...onChanged,
      ],
      (ButtonNode(:final onTap), 'onTap') => onTap,
      (IconButtonNode(:final loading), 'onTap') when _running > 0 && (loading.resolve(values) ?? false) => null,
      (IconButtonNode(:final onTap), 'onTap') => onTap,
      (DayPickerNode(:final onPrevious), 'onPrevious') => onPrevious,
      (DayPickerNode(:final onNext), 'onNext') => onNext,
      _ => null,
    };
  }

  void _render(GenericState state) => _rendered = _rendered.then((_) => _save(state));

  Future<void> _save(GenericState state) async {
    final page = state.page;
    if (page == null) return;
    final snapshot = WidgetSnapshotResolver.resolve(page, state.values);
    if (await _snapshots.save(snapshot, page: page, values: state.values) case Ok()) {
      await _snapshots.update();
    }
  }
}
