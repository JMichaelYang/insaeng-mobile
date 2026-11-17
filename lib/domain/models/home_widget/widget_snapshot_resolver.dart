import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_page.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/domain/models/home_widget/widget_snapshot.dart';

final class WidgetSnapshotResolver {
  const new _(this._values);

  final GenericValues _values;

  static WidgetSnapshot resolve(GenericPage page, GenericValues values) => WidgetSnapshot(
    pageId: page.id,
    root: WidgetSnapshotResolver._(values)._resolve(page.root) ?? WidgetNode(type: 'column', id: page.root.id),
  );

  WidgetNode? _resolve(GenericNode? node) => switch (node) {
    null || AppBarNode() || TextFieldNode() => null,
    UnknownNode(:final fallback) => _resolve(fallback),
    ColumnNode(:final id, :final children, :final spacing, :final alignment) => _node(
      'column',
      id,
      props: {'spacing': spacing, 'alignment': alignment},
      children: children,
    ),
    RowNode(:final id, :final children, :final spacing, :final alignment) => _node(
      'row',
      id,
      props: {'spacing': spacing, 'alignment': alignment},
      children: children,
    ),
    ContainerNode(:final id, :final child, :final padding, :final alignment) => _node(
      'container',
      id,
      props: {'padding': padding, 'alignment': alignment},
      children: [?child],
    ),
    ExpandedNode(:final id, :final child, :final flex) => _node(
      'expanded',
      id,
      props: {'flex': flex},
      children: [?child],
    ),
    ScrollNode(:final id, :final child) => _node('scroll', id, children: [?child]),
    SpacerNode(:final id, :final size) => _node('spacer', id, props: {'size': size}),
    DividerNode(:final id) => _node('divider', id),
    ProgressBarNode(:final id, :final value, :final max) => _node(
      'progressBar',
      id,
      props: {'value': value, 'max': max},
    ),
    TextNode(:final id, :final text, :final style) => _node('text', id, props: {'text': text, 'style': style}),
    ButtonNode(:final id, :final label, :final variant, :final loading, :final onTap) => _node(
      'button',
      id,
      props: {'label': label, 'variant': variant, 'loading': loading},
      tap: _tap(id, 'onTap', onTap),
    ),
    IconButtonNode(:final id, :final icon, :final label, :final loading, :final onTap) => _node(
      'iconButton',
      id,
      props: {'icon': icon, 'label': label, 'loading': loading},
      tap: _tap(id, 'onTap', onTap),
    ),
    DayPickerNode(:final id, :final label, :final previousLabel, :final nextLabel, :final onPrevious, :final onNext) =>
      WidgetNode(
        type: 'dayPicker',
        id: id,
        props: _props({'label': label}),
        children: [
          _chevron('${id}Previous', IconToken.chevronLeft, previousLabel, _tap(id, 'onPrevious', onPrevious)),
          _chevron('${id}Next', IconToken.chevronRight, nextLabel, _tap(id, 'onNext', onNext)),
        ],
      ),
    CheckboxTileNode(
      :final id,
      :final bind,
      :final title,
      :final subtitle,
      :final emoji,
      :final busy,
      :final onChanged,
    ) =>
      _node(
        'checkboxTile',
        id,
        props: {
          'title': title,
          'subtitle': subtitle,
          'emoji': emoji,
          'busy': busy,
          'checked': Literal(Binding<bool>(bind).resolve(_values) ?? false),
        },
        tap: _tap(id, 'onChanged', onChanged),
      ),
  };

  WidgetNode _node(
    String type,
    String id, {
    Map<String, Bindable<Object>?> props = const {},
    List<GenericNode> children = const [],
    WidgetTap? tap,
  }) => WidgetNode(
    type: type,
    id: id,
    props: _props(props),
    children: [for (final child in children) ?_resolve(child)],
    tap: tap,
  );

  Map<String, Object?> _props(Map<String, Bindable<Object>?> props) => {
    for (final MapEntry(:key, value: bindable) in props.entries) key: ?_literal(bindable?.resolve(_values)),
  };

  WidgetNode _chevron(String id, IconToken icon, Bindable<String> label, WidgetTap? tap) =>
      _node('iconButton', id, props: {'icon': Literal(icon), 'label': label}, tap: tap);

  static Object? _literal(Object? value) => switch (value) {
    final Enum token => token.name,
    final Map<Object?, Object?> map => {for (final MapEntry(:key, :value) in map.entries) '$key': _literal(value)},
    final List<Object?> list => [for (final item in list) _literal(item)],
    _ => value,
  };

  WidgetTap? _tap(String nodeId, String event, List<GenericAction> actions) => switch (actions) {
    [] => null,
    [NavigateAction()] => const OpenAppTap(),
    [OpenUrlAction(:final url)] => switch (url.resolve(_values)) {
      null => null,
      final resolved => OpenUrlTap(url: resolved),
    },
    _ => EventTap(nodeId: nodeId, event: event),
  };
}
