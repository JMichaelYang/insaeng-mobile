import 'package:collection/collection.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/bindable_json.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_page.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:intl/intl.dart';

typedef MyDayRowsMapper = GenericPage Function(
  Iterable<Map<String, Object?>> rows, {
  required DateTime day,
  required DateTime today,
});

typedef _Task = ({
  String id,
  String emoji,
  String title,
  String? status,
  bool allDay,
  DateTime start,
  DateTime? end,
  DateTime? editedAt,
});

abstract final class MyDayPageMapper {
  static const pageId = 'myDay';
  static const widgetPageId = 'myDayWidget';
  static const title = 'My Day';
  static const emptyText = 'Nothing planned';
  static const connectInAppText = 'Connect Notion in the app';
  static const skippedText = 'Skipped';
  static const saveErrorText = "Couldn't update the task. Try again.";
  static const fallbackEmoji = '📝';
  static const progressDonePath = 'progress.done';
  static const previousDayLabel = 'Previous day';
  static const nextDayLabel = 'Next day';
  static const todayHint = 'Go to today';
  static const selectedDayEndpoint = '/my-day/selected-day';
  static const selectableDays = 7;
  static const refreshLabel = 'Refresh';
  static const refreshingPath = 'refreshing';

  static const _doneStatus = 'Done';
  static const _skippedStatus = 'Skipped';
  static const _canceledStatus = 'Canceled';

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

  static final _dateFormat = DateFormat('yyyy-MM-dd');
  static final _labelFormat = DateFormat('EEE, MMM d');

  static String formatDate(DateTime day) => _dateFormat.format(day);

  static DateTime? parseDate(Object? value) => switch (value) {
    final String value => switch (_dateFormat.tryParseStrict(value)) {
      final day? when formatDate(day) == value => day,
      _ => null,
    },
    _ => null,
  };

  static DateTime dateOf(DateTime time) => DateTime(time.year, time.month, time.day);

  static DateTime clampDay(DateTime day, {required DateTime today}) {
    final date = dateOf(day);
    final first = _addDays(today, -selectableDays);
    final last = _addDays(today, selectableDays);
    return date.isBefore(first) ? first : (date.isAfter(last) ? last : date);
  }

  static GenericPage fromRows(Iterable<Map<String, Object?>> rows, {required DateTime day, required DateTime today}) {
    final tasks = _dayTasks(rows, day);
    return GenericPage(
      id: pageId,
      state: _state(tasks),
      root: ColumnNode(
        id: 'root',
        children: [
          const AppBarNode(id: 'appBar', title: Literal(title)),
          _dayPicker(pageId, day, today),
          ContainerNode(
            id: 'progressBar',
            padding: const Literal(SpacingToken.md),
            alignment: const Literal(AlignmentToken.stretch),
            child: _progress(tasks),
          ),
          ExpandedNode(
            id: 'body',
            child: ScrollNode(id: 'scroll', onRefresh: const [ReloadAction()], child: _taskList(tasks, reload: true)),
          ),
        ],
      ),
    );
  }

  static GenericPage widgetFromRows(
    Iterable<Map<String, Object?>> rows, {
    required DateTime day,
    required DateTime today,
  }) {
    final tasks = _dayTasks(rows, day);
    return GenericPage(
      id: widgetPageId,
      state: _state(tasks),
      root: ColumnNode(
        id: 'root',
        spacing: const Literal(SpacingToken.sm),
        children: [
          _dayPicker(widgetPageId, day, today),
          _progress(tasks),
          ExpandedNode(
            id: 'body',
            child: tasks.isEmpty
                ? _empty
                : ScrollNode(id: 'scroll', child: _taskList(tasks, dividers: false, reload: false)),
          ),
          _footer,
        ],
      ),
    );
  }

  static const _footer = RowNode(
    id: 'footer',
    alignment: Literal(AlignmentToken.center),
    children: [
      ExpandedNode(
        id: 'footerStart',
        child: ContainerNode(
          id: 'footerStartSlot',
          child: IconButtonNode(
            id: 'refresh',
            icon: Literal(IconToken.refresh),
            label: Literal(refreshLabel),
            loading: Binding(refreshingPath, fallback: false),
            onTap: [
              UpdateStateAction(path: refreshingPath, value: Literal(true)),
              ReloadAction(
                onComplete: [UpdateStateAction(path: refreshingPath, value: Literal(false))],
              ),
            ],
          ),
        ),
      ),
    ],
  );

  static List<_Task> _dayTasks(Iterable<Map<String, Object?>> rows, DateTime day) => rows
      .map(_task)
      .nonNulls
      .where((task) => _isSameDay(task.start, day) && task.status != _canceledStatus)
      .sortedByCompare((task) => task, _compare);

  static DayPickerNode _dayPicker(String id, DateTime day, DateTime today) => DayPickerNode(
    id: 'dayPicker',
    label: Literal(_labelFormat.format(day)),
    previousLabel: const Literal(previousDayLabel),
    nextLabel: const Literal(nextDayLabel),
    onPrevious: _selectDay(id, _addDays(day, -1), today),
    onNext: _selectDay(id, _addDays(day, 1), today),
    labelTapHint: const Literal(todayHint),
    onLabelTap: day == today ? const [] : _selectDay(id, today, today),
  );

  static List<GenericAction> _selectDay(String id, DateTime day, DateTime today) => clampDay(day, today: today) == day
      ? [
          RequestAction(
            method: const Literal(RequestMethod.put),
            endpoint: const Literal(selectedDayEndpoint),
            body: JsonObject({'pageId': JsonLiteral(id), 'date': JsonLiteral(formatDate(day))}),
          ),
        ]
      : const [];

  static DateTime _addDays(DateTime day, int days) => DateTime(day.year, day.month, day.day + days);

  static GenericValues _state(List<_Task> tasks) => GenericValues({
    'tasks': {
      for (final task in tasks) task.id: {'done': _isChecked(task), 'saving': false},
    },
    'progress': {'done': tasks.where(_isChecked).length},
  });

  static ProgressBarNode _progress(List<_Task> tasks) =>
      ProgressBarNode(id: 'progress', value: const Binding(progressDonePath, fallback: 0), max: Literal(tasks.length));

  static const _empty = ContainerNode(
    id: 'empty',
    padding: Literal(SpacingToken.md),
    alignment: Literal(AlignmentToken.center),
    child: TextNode(id: 'emptyText', text: Literal(emptyText)),
  );

  static GenericNode _taskList(List<_Task> tasks, {required bool reload, bool dividers = true}) => tasks.isEmpty
      ? _empty
      : ColumnNode(
          id: 'tasks',
          children: [
            for (final (index, task) in tasks.indexed) ...[
              if (dividers && index > 0) DividerNode(id: 'divider-${tasks[index - 1].id}'),
              _tile(task, reload: reload),
            ],
          ],
        );

  static CheckboxTileNode _tile(_Task task, {required bool reload}) {
    final donePath = 'tasks.${task.id}.done';
    final savingPath = 'tasks.${task.id}.saving';
    final clearSaving = UpdateStateAction(path: savingPath, value: const Literal(false));
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
      mark: Literal(task.status == _skippedStatus ? CheckboxMark.dash : CheckboxMark.check),
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
          onComplete: [
            if (reload) ReloadAction(onComplete: [clearSaving]) else clearSaving,
          ],
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
          editedAt: switch (row['last_edited_time']) {
            final String edited => DateTime.tryParse(edited),
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

  static int _compare(_Task a, _Task b) => switch (_group(a).compareTo(_group(b))) {
    0 when _isChecked(a) => switch (_compareCompletion(a, b)) {
      0 => _compareSchedule(a, b),
      final order => order,
    },
    0 => _compareSchedule(a, b),
    final order => order,
  };

  static int _group(_Task task) => switch (task.status) {
    _doneStatus => 1,
    _skippedStatus => 2,
    _ => 0,
  };

  static int _compareCompletion(_Task a, _Task b) => switch ((a.editedAt, b.editedAt)) {
    (final aAt?, final bAt?) => bAt.compareTo(aAt),
    (_?, null) => -1,
    (null, _?) => 1,
    (null, null) => 0,
  };

  static int _compareSchedule(_Task a, _Task b) => switch ((a.allDay, b.allDay)) {
    (true, false) => -1,
    (false, true) => 1,
    _ => a.start.compareTo(b.start),
  };

  static bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}
