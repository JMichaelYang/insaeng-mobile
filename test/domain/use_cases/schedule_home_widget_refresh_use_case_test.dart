import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/repositories/background_task_repository.dart';
import 'package:insaeng/domain/result.dart';
import 'package:insaeng/domain/use_cases/schedule_home_widget_refresh_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockBackgroundTaskRepository extends Mock implements BackgroundTaskRepository;

final DateTime _now = DateTime(2026, 1, 31, 23, 30);

void main() {
  group(ScheduleHomeWidgetRefreshUseCase, () {
    late BackgroundTaskRepository tasks;
    late ScheduleHomeWidgetRefreshUseCase useCase;

    Future<Result<void>> schedulePeriodic() => tasks.schedulePeriodic(
      any(),
      frequency: any(named: 'frequency'),
      requiresNetwork: any(named: 'requiresNetwork'),
      replace: any(named: 'replace'),
    );

    Future<Result<void>> scheduleOnce() => tasks.scheduleOnce(
      any(),
      delay: any(named: 'delay'),
      requiresNetwork: any(named: 'requiresNetwork'),
      replace: any(named: 'replace'),
    );

    setUpAll(() => registerFallbackValue(Duration.zero));

    setUp(() {
      tasks = _MockBackgroundTaskRepository();
      useCase = ScheduleHomeWidgetRefreshUseCase(tasks, now: () => _now);
      when(schedulePeriodic).thenAnswer((_) async => const Result.ok(null));
      when(scheduleOnce).thenAnswer((_) async => const Result.ok(null));
    });

    for (final replace in [true, false]) {
      test('schedules the periodic refresh every 15 minutes on a network with replace: $replace', () async {
        expect(await useCase(replace: replace), const Result<void>.ok(null));

        verify(
          () => tasks.schedulePeriodic(
            ScheduleHomeWidgetRefreshUseCase.periodicTask,
            frequency: const Duration(minutes: 15),
            requiresNetwork: true,
            replace: replace,
          ),
        ).called(1);
      });

      test('schedules the midnight refresh a minute past the next midnight with replace: $replace', () async {
        await useCase(replace: replace);

        verify(
          () => tasks.scheduleOnce(
            ScheduleHomeWidgetRefreshUseCase.midnightTask,
            delay: const Duration(minutes: 31),
            requiresNetwork: true,
            replace: replace,
          ),
        ).called(1);
      });
    }

    test('returns the periodic failure without scheduling the midnight refresh', () async {
      when(schedulePeriodic).thenAnswer((_) async => const Result.err(BackgroundTaskPlatformError()));

      expect(await useCase(replace: true), const Result<void>.err(BackgroundTaskPlatformError()));
      verifyNever(scheduleOnce);
    });

    test('returns the midnight failure', () async {
      when(scheduleOnce).thenAnswer((_) async => const Result.err(BackgroundTaskPlatformError()));

      expect(await useCase(replace: true), const Result<void>.err(BackgroundTaskPlatformError()));
    });

    group('untilAfterMidnight', () {
      test('waits until a minute past the next midnight across a month boundary', () {
        expect(ScheduleHomeWidgetRefreshUseCase.untilAfterMidnight(_now), const Duration(minutes: 31));
      });

      test('waits a full day when called at midnight', () {
        expect(
          ScheduleHomeWidgetRefreshUseCase.untilAfterMidnight(DateTime(2026, 3)),
          const Duration(days: 1, minutes: 1),
        );
      });
    });
  });
}
