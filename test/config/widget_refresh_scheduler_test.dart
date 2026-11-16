import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/config/flavor.dart';
import 'package:insaeng/config/widget_refresh_scheduler.dart';
import 'package:insaeng/domain/repositories/widget_snapshot_repository.dart';
import 'package:insaeng/domain/result.dart';
import 'package:insaeng/domain/use_cases/refresh_home_widget_use_case.dart';
import 'package:mocktail/mocktail.dart';
import 'package:workmanager/workmanager.dart';

class _MockWorkmanager extends Mock implements Workmanager;

class _MockRefreshHomeWidgetUseCase extends Mock implements RefreshHomeWidgetUseCase;

final DateTime _now = DateTime(2026, 1, 31, 23, 30);

void main() {
  group(WidgetRefreshScheduler, () {
    late Workmanager workmanager;
    late RefreshHomeWidgetUseCase refresh;
    late WidgetRefreshScheduler scheduler;

    Future<void> registerOneOff() => workmanager.registerOneOffTask(
      any(),
      any(),
      initialDelay: any(named: 'initialDelay'),
      inputData: any(named: 'inputData'),
      constraints: any(named: 'constraints'),
      existingWorkPolicy: any(named: 'existingWorkPolicy'),
    );

    Future<void> registerPeriodic() => workmanager.registerPeriodicTask(
      any(),
      any(),
      frequency: any(named: 'frequency'),
      inputData: any(named: 'inputData'),
      constraints: any(named: 'constraints'),
      existingWorkPolicy: any(named: 'existingWorkPolicy'),
    );

    setUpAll(() {
      registerFallbackValue(Duration.zero);
      registerFallbackValue(Constraints());
      registerFallbackValue(ExistingWorkPolicy.keep);
      registerFallbackValue(ExistingPeriodicWorkPolicy.keep);
      registerFallbackValue(<String, dynamic>{});
    });

    setUp(() {
      workmanager = _MockWorkmanager();
      refresh = _MockRefreshHomeWidgetUseCase();
      scheduler = WidgetRefreshScheduler(workmanager, refresh, Flavor.dev, now: () => _now);
      when(() => workmanager.initialize(any())).thenAnswer((_) async {});
      when(registerOneOff).thenAnswer((_) async {});
      when(registerPeriodic).thenAnswer((_) async {});
      when(() => refresh(any())).thenAnswer((_) async => const Result.ok(null));
    });

    group('untilAfterMidnight', () {
      test('waits until a minute past the next midnight', () {
        expect(WidgetRefreshScheduler.untilAfterMidnight(_now), const Duration(minutes: 31));
      });

      test('waits a full day when called at midnight', () {
        expect(WidgetRefreshScheduler.untilAfterMidnight(DateTime(2026, 3)), const Duration(days: 1, minutes: 1));
      });
    });

    group('start', () {
      test('initializes workmanager with the dispatcher', () async {
        await scheduler.start();

        verify(() => workmanager.initialize(widgetRefreshDispatcher)).called(1);
      });

      test('registers the periodic refresh every 15 minutes on a network', () async {
        await scheduler.start();

        final captured = verify(
          () => workmanager.registerPeriodicTask(
            WidgetRefreshScheduler.periodicTask,
            WidgetRefreshScheduler.periodicTask,
            frequency: const Duration(minutes: 15),
            inputData: {'flavor': 'dev'},
            constraints: captureAny(named: 'constraints'),
            existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
          ),
        ).captured;
        expect((captured.single as Constraints).networkType, NetworkType.connected);
      });

      test('replaces the midnight refresh with one a minute past the next midnight', () async {
        await scheduler.start();

        final captured = verify(
          () => workmanager.registerOneOffTask(
            WidgetRefreshScheduler.midnightTask,
            WidgetRefreshScheduler.midnightTask,
            initialDelay: const Duration(minutes: 31),
            inputData: {'flavor': 'dev'},
            constraints: captureAny(named: 'constraints'),
            existingWorkPolicy: ExistingWorkPolicy.replace,
          ),
        ).captured;
        expect((captured.single as Constraints).networkType, NetworkType.connected);
      });

      test('initializes before registering tasks', () async {
        await scheduler.start();

        verifyInOrder([() => workmanager.initialize(any()), registerPeriodic, registerOneOff]);
      });
    });

    group('run', () {
      test('refreshes the widget page for the periodic task', () async {
        expect(await scheduler.run(WidgetRefreshScheduler.periodicTask), isTrue);

        verify(() => refresh('myDayWidget')).called(1);
      });

      test('keeps a pending midnight refresh for the periodic task', () async {
        await scheduler.run(WidgetRefreshScheduler.periodicTask);

        verify(
          () => workmanager.registerOneOffTask(
            WidgetRefreshScheduler.midnightTask,
            WidgetRefreshScheduler.midnightTask,
            initialDelay: const Duration(minutes: 31),
            inputData: {'flavor': 'dev'},
            constraints: any(named: 'constraints'),
            existingWorkPolicy: ExistingWorkPolicy.keep,
          ),
        ).called(1);
      });

      test('refreshes the widget page for the midnight task without rescheduling', () async {
        expect(await scheduler.run(WidgetRefreshScheduler.midnightTask), isTrue);

        verify(() => refresh('myDayWidget')).called(1);
        verifyNever(registerOneOff);
      });

      test('succeeds when the refresh fails', () async {
        when(() => refresh(any())).thenAnswer((_) async => const Result.err(WidgetSnapshotPlatformError()));

        expect(await scheduler.run(WidgetRefreshScheduler.midnightTask), isTrue);
      });
    });
  });
}
