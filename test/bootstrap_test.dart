import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/bootstrap.dart';
import 'package:insaeng/config/dependencies.dart';
import 'package:insaeng/config/flavor.dart';
import 'package:insaeng/domain/repositories/background_task_repository.dart';
import 'package:insaeng/domain/result.dart';
import 'package:insaeng/domain/use_cases/refresh_home_widget_use_case.dart';
import 'package:insaeng/domain/use_cases/schedule_home_widget_refresh_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockRefreshHomeWidgetUseCase extends Mock implements RefreshHomeWidgetUseCase;

class _MockScheduleHomeWidgetRefreshUseCase extends Mock implements ScheduleHomeWidgetRefreshUseCase;

void main() {
  tearDown(getIt.reset);

  group(bootstrapBackground, () {
    for (final flavor in Flavor.values) {
      test('configures dependencies for ${flavor.name}', () {
        bootstrapBackground(flavor);

        expect(getIt<Flavor>(), flavor);
        expect(getIt<RefreshHomeWidgetUseCase>(), isA<RefreshHomeWidgetUseCase>());
      });
    }

    test('keeps dependencies that are already configured', () {
      bootstrapBackground(Flavor.dev);
      bootstrapBackground(Flavor.prod);

      expect(getIt<Flavor>(), Flavor.dev);
    });
  });

  group(runBackgroundTask, () {
    late RefreshHomeWidgetUseCase refresh;
    late ScheduleHomeWidgetRefreshUseCase schedule;

    setUp(() {
      refresh = _MockRefreshHomeWidgetUseCase();
      schedule = _MockScheduleHomeWidgetRefreshUseCase();
      when(() => refresh(any())).thenAnswer((_) async => const Result.ok(null));
      when(() => schedule(replace: any(named: 'replace'))).thenAnswer((_) async => const Result.ok(null));
      getIt
        ..registerSingleton(Flavor.dev)
        ..registerSingleton(refresh)
        ..registerSingleton(schedule);
    });

    test('refreshes the widget and keeps the schedule for the periodic task', () async {
      expect(await runBackgroundTask(ScheduleHomeWidgetRefreshUseCase.periodicTask, null), isTrue);

      verify(() => refresh('myDayWidget')).called(1);
      verify(() => schedule(replace: false)).called(1);
    });

    test('refreshes the widget without rescheduling for the midnight task', () async {
      expect(await runBackgroundTask(ScheduleHomeWidgetRefreshUseCase.midnightTask, null), isTrue);

      verify(() => refresh('myDayWidget')).called(1);
      verifyNever(() => schedule(replace: any(named: 'replace')));
    });

    test('succeeds when the refresh and schedule fail', () async {
      when(() => refresh(any())).thenAnswer((_) async => const Result.err(BackgroundTaskPlatformError()));
      when(() => schedule(replace: any(named: 'replace')))
          .thenAnswer((_) async => const Result.err(BackgroundTaskPlatformError()));

      expect(await runBackgroundTask(ScheduleHomeWidgetRefreshUseCase.periodicTask, null), isTrue);
    });

    test('ignores unknown tasks', () async {
      expect(await runBackgroundTask('unknown', null), isTrue);

      verifyNever(() => refresh(any()));
      verifyNever(() => schedule(replace: any(named: 'replace')));
    });

    test('keeps dependencies that are already configured', () async {
      await runBackgroundTask(ScheduleHomeWidgetRefreshUseCase.midnightTask, {backgroundFlavorKey: 'prod'});

      expect(getIt<Flavor>(), Flavor.dev);
    });
  });
}
