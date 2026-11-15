import 'package:collection/collection.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/bindable_json.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_page.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';

typedef _Task = ({String id, String title, String? status, bool allDay, DateTime start, DateTime? end});

abstract final class MyDayPageMapper {
  static const pageId = 'myDay';
  static const title = 'My Day';
  static const emptyText = 'Nothing planned today';
  static const skippedText = 'Skipped';

  static const _doneStatus = 'Done';
  static const _skippedStatus = 'Skipped';

  static GenericPage fromRows(Iterable<Map<String, Object?>> rows, {required DateTime now}) {
    final today = now.toLocal();
    final tasks = rows
        .map(_task)
        .nonNulls
        .where((task) => _isSameDay(task.start, today))
        .sortedByCompare((task) => task, _compare);
    return GenericPage(
      id: pageId,
      state: GenericValues({
        'tasks': {
          for (final task in tasks) task.id: {'done': _isChecked(task), 'saving': false},
        },
      }),
      root: ColumnNode(
        id: 'root',
        children: [
          const AppBarNode(id: 'appBar', title: Literal(title)),
          ExpandedNode(
            id: 'body',
            child: ScrollNode(
              id: 'scroll',
              onRefresh: const [ReloadAction()],
              child: tasks.isEmpty
                  ? const ContainerNode(
                      id: 'empty',
                      padding: Literal(SpacingToken.md),
                      alignment: Literal(AlignmentToken.center),
                      child: TextNode(id: 'emptyText', text: Literal(emptyText)),
                    )
                  : ColumnNode(id: 'tasks', children: [for (final task in tasks) _tile(task)]),
            ),
          ),
        ],
      ),
    );
  }

  static CheckboxTileNode _tile(_Task task) {
    final donePath = 'tasks.${task.id}.done';
    final savingPath = 'tasks.${task.id}.saving';
    return CheckboxTileNode(
      id: 'task-${task.id}',
      bind: donePath,
      title: Literal(task.title),
      subtitle: switch (_subtitle(task)) {
        final subtitle? => Literal(subtitle),
        null => null,
      },
      busy: Binding(savingPath, fallback: false),
      onChanged: [
        UpdateStateAction(path: savingPath, value: const Literal(true)),
        RequestAction(
          method: const Literal(RequestMethod.patch),
          endpoint: Literal('/my-day/tasks/${task.id}'),
          body: JsonObject({'done': JsonBinding(Binding(donePath))}),
          onError: [UpdateStateAction(path: donePath, op: const Literal(UpdateOp.toggle))],
          onComplete: [UpdateStateAction(path: savingPath, value: const Literal(false))],
        ),
      ],
    );
  }

  static _Task? _task(Map<String, Object?> row) {
    if (row case {'id': final String id, 'properties': final Map<Object?, Object?> properties}) {
      if (properties['Date'] case {'date': {'start': final String start} && final Map<Object?, Object?> date}) {
        final startAt = DateTime.tryParse(start);
        if (startAt == null) return null;
        return (
          id: id,
          title: _title(properties),
          status: _status(properties),
          allDay: !start.contains('T'),
          start: startAt.toLocal(),
          end: switch (date['end']) {
            final String end => DateTime.tryParse(end)?.toLocal(),
            _ => null,
          },
        );
      }
    }
    return null;
  }

  static String _title(Map<Object?, Object?> properties) =>
      properties.values
          .map(
            (property) => switch (property) {
              {'type': 'title', 'title': final List<Object?> parts} =>
                parts
                    .map(
                      (part) => switch (part) {
                        {'plain_text': final String text} => text,
                        _ => '',
                      },
                    )
                    .join(),
              _ => null,
            },
          )
          .nonNulls
          .firstOrNull ??
      '';

  static String? _status(Map<Object?, Object?> properties) => switch (properties['Status']) {
    {'status': {'name': final String name}} => name,
    _ => null,
  };

  static bool _isChecked(_Task task) => task.status == _doneStatus || task.status == _skippedStatus;

  static String? _subtitle(_Task task) {
    final parts = [
      if (!task.allDay) [task.start, ?task.end].map(_time).join('–'),
      if (task.status == _skippedStatus) skippedText,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  static String _time(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  static int _compare(_Task a, _Task b) => switch ((a.allDay, b.allDay)) {
    (true, false) => -1,
    (false, true) => 1,
    _ => a.start.compareTo(b.start),
  };

  static bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}
