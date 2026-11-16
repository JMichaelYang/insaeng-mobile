import 'package:collection/collection.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/bindable_json.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_page.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';

typedef MyDayRowsMapper = GenericPage Function(Iterable<Map<String, Object?>> rows, {required DateTime now});

typedef _Task = ({String id, String emoji, String title, String? status, bool allDay, DateTime start, DateTime? end});

abstract final class MyDayPageMapper {
  static const pageId = 'myDay';
  static const widgetPageId = 'myDayWidget';
  static const title = 'My Day';
  static const emptyText = 'Nothing planned today';
  static const connectInAppText = 'Connect Notion in the app';
  static const skippedText = 'Skipped';
  static const saveErrorText = "Couldn't update the task. Try again.";
  static const fallbackEmoji = '📝';

  static const _doneStatus = 'Done';
  static const _skippedStatus = 'Skipped';

  static const GenericPage widgetConnectPage = GenericPage(
    id: widgetPageId,
    root: ColumnNode(
      id: 'root',
      children: [
        ExpandedNode(
          id: 'body',
          child: ContainerNode(
            id: 'connect',
            padding: Literal(SpacingToken.md),
            alignment: Literal(AlignmentToken.center),
            child: ButtonNode(
              id: 'connectPrompt',
              label: Literal(connectInAppText),
              variant: Literal(ButtonVariant.text),
              onTap: _openMyDay,
            ),
          ),
        ),
      ],
    ),
  );

  static const _openMyDay = [NavigateAction(pageId: Literal(pageId))];

  static GenericPage fromRows(Iterable<Map<String, Object?>> rows, {required DateTime now}) {
    final tasks = _todayTasks(rows, now);
    return GenericPage(
      id: pageId,
      state: _state(tasks),
      root: ColumnNode(
        id: 'root',
        children: [
          const AppBarNode(id: 'appBar', title: Literal(title)),
          ExpandedNode(
            id: 'body',
            child: ScrollNode(id: 'scroll', onRefresh: const [ReloadAction()], child: _taskList(tasks)),
          ),
        ],
      ),
    );
  }

  static GenericPage widgetFromRows(Iterable<Map<String, Object?>> rows, {required DateTime now}) {
    final tasks = _todayTasks(rows, now);
    return GenericPage(
      id: widgetPageId,
      state: _state(tasks),
      root: ColumnNode(
        id: 'root',
        children: [
          ExpandedNode(
            id: 'body',
            child: ScrollNode(id: 'scroll', child: _taskList(tasks, dividers: false)),
          ),
        ],
      ),
    );
  }

  static List<_Task> _todayTasks(Iterable<Map<String, Object?>> rows, DateTime now) {
    final today = now.toLocal();
    return rows
        .map(_task)
        .nonNulls
        .where((task) => _isSameDay(task.start, today))
        .sortedByCompare((task) => task, _compare);
  }

  static GenericValues _state(List<_Task> tasks) => GenericValues({
    'tasks': {
      for (final task in tasks) task.id: {'done': _isChecked(task), 'saving': false},
    },
  });

  static GenericNode _taskList(List<_Task> tasks, {bool dividers = true}) => tasks.isEmpty
      ? const ContainerNode(
          id: 'empty',
          padding: Literal(SpacingToken.md),
          alignment: Literal(AlignmentToken.center),
          child: TextNode(id: 'emptyText', text: Literal(emptyText)),
        )
      : ColumnNode(
          id: 'tasks',
          children: [
            for (final (index, task) in tasks.indexed) ...[
              if (dividers && index > 0) DividerNode(id: 'divider-${tasks[index - 1].id}'),
              _tile(task),
            ],
          ],
        );

  static CheckboxTileNode _tile(_Task task) {
    final donePath = 'tasks.${task.id}.done';
    final savingPath = 'tasks.${task.id}.saving';
    return CheckboxTileNode(
      id: 'task-${task.id}',
      bind: donePath,
      emoji: Literal(task.emoji),
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
          onError: [
            UpdateStateAction(path: donePath, op: const Literal(UpdateOp.toggle)),
            const ShowMessageAction(text: Literal(saveErrorText)),
          ],
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
          emoji: _emoji(row),
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

  static String _emoji(Map<String, Object?> row) => switch (row['icon']) {
    {'type': 'emoji', 'emoji': final String emoji} => emoji,
    _ => fallbackEmoji,
  };

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
    final parts = [if (!task.allDay) _timeRange(task.start, task.end), if (task.status == _skippedStatus) skippedText];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  static String _timeRange(DateTime start, DateTime? end) => switch (end) {
    null => '${_clock(start)} ${_period(start)}',
    _ when _period(start) == _period(end) => '${_clock(start)} – ${_clock(end)} ${_period(end)}',
    _ => '${_clock(start)} ${_period(start)} – ${_clock(end)} ${_period(end)}',
  };

  static String _clock(DateTime time) => '${(time.hour + 11) % 12 + 1}:${time.minute.toString().padLeft(2, '0')}';

  static String _period(DateTime time) => time.hour < 12 ? 'AM' : 'PM';

  static int _compare(_Task a, _Task b) => switch ((a.allDay, b.allDay)) {
    (true, false) => -1,
    (false, true) => 1,
    _ => a.start.compareTo(b.start),
  };

  static bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}
