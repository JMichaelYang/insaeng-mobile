import 'package:insaeng/domain/repositories/background_task_repository.dart';
import 'package:insaeng/domain/result.dart';

class ScheduleHomeWidgetRefreshUseCase {
  new(this._tasks, {this._now = DateTime.now});

  final BackgroundTaskRepository _tasks;
  final DateTime Function() _now;

  static const periodicTask = 'homeWidgetRefresh.periodic';
  static const midnightTask = 'homeWidgetRefresh.midnight';
  static const frequency = Duration(minutes: 15);
  static const afterMidnight = Duration(minutes: 1);

  Future<Result<void>> call({required bool replace}) async => switch (await _tasks.schedulePeriodic(
    periodicTask,
    frequency: frequency,
    requiresNetwork: true,
    replace: replace,
  )) {
    Err(:final failure) => Result.err(failure),
    Ok() => await _tasks.scheduleOnce(
      midnightTask,
      delay: untilAfterMidnight(_now()),
      requiresNetwork: true,
      replace: replace,
    ),
  };

  static Duration untilAfterMidnight(DateTime now) =>
      DateTime(now.year, now.month, now.day + 1).add(afterMidnight).difference(now);
}
