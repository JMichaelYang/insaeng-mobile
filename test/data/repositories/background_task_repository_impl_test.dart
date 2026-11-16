import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/data/repositories/background_task_repository_impl.dart';
import 'package:insaeng/data/services/background_task_service.dart';
import 'package:insaeng/domain/repositories/background_task_repository.dart';
import 'package:insaeng/domain/result.dart';
import 'package:mocktail/mocktail.dart';
import 'package:workmanager/workmanager.dart';

class _MockBackgroundTaskService extends Mock implements BackgroundTaskService;

const Map<String, dynamic> _inputData = {'flavor': 'dev'};

void main() {
  group(BackgroundTaskRepositoryImpl, () {
    late BackgroundTaskService service;
    late BackgroundTaskRepositoryImpl repository;

    Future<void> registerPeriodic() => service.registerPeriodic(
      any(),
      frequency: any(named: 'frequency'),
      inputData: any(named: 'inputData'),
      constraints: any(named: 'constraints'),
      policy: any(named: 'policy'),
    );

    Future<void> registerOneOff() => service.registerOneOff(
      any(),
      delay: any(named: 'delay'),
      inputData: any(named: 'inputData'),
      constraints: any(named: 'constraints'),
      policy: any(named: 'policy'),
    );

    setUpAll(() {
      registerFallbackValue(Duration.zero);
      registerFallbackValue(Constraints());
      registerFallbackValue(ExistingWorkPolicy.keep);
      registerFallbackValue(ExistingPeriodicWorkPolicy.keep);
      registerFallbackValue(<String, dynamic>{});
    });

    setUp(() {
      service = _MockBackgroundTaskService();
      repository = BackgroundTaskRepositoryImpl(service, inputData: _inputData);
      when(registerPeriodic).thenAnswer((_) async {});
      when(registerOneOff).thenAnswer((_) async {});
    });

    group('schedulePeriodic', () {
      test('updates the task with the input data and a network constraint', () async {
        final result = await repository.schedulePeriodic(
          'task',
          frequency: const Duration(minutes: 15),
          requiresNetwork: true,
          replace: true,
        );

        expect(result, const Result<void>.ok(null));
        final captured = verify(
          () => service.registerPeriodic(
            'task',
            frequency: const Duration(minutes: 15),
            inputData: _inputData,
            constraints: captureAny(named: 'constraints'),
            policy: ExistingPeriodicWorkPolicy.update,
          ),
        ).captured;
        expect((captured.single as Constraints).networkType, NetworkType.connected);
      });

      test('keeps existing work and needs no network when asked', () async {
        await repository.schedulePeriodic('task', frequency: Duration.zero, requiresNetwork: false, replace: false);

        final captured = verify(
          () => service.registerPeriodic(
            'task',
            frequency: Duration.zero,
            inputData: _inputData,
            constraints: captureAny(named: 'constraints'),
            policy: ExistingPeriodicWorkPolicy.keep,
          ),
        ).captured;
        expect((captured.single as Constraints).networkType, NetworkType.notRequired);
      });

      test('returns a platform error when registering fails', () async {
        when(registerPeriodic).thenThrow(PlatformException(code: 'register'));

        expect(
          await repository.schedulePeriodic('task', frequency: Duration.zero, requiresNetwork: true, replace: true),
          const Result<void>.err(BackgroundTaskPlatformError()),
        );
      });

      test('returns a platform error when the plugin is missing', () async {
        when(registerPeriodic).thenThrow(MissingPluginException());

        expect(
          await repository.schedulePeriodic('task', frequency: Duration.zero, requiresNetwork: true, replace: true),
          const Result<void>.err(BackgroundTaskPlatformError()),
        );
      });
    });

    group('scheduleOnce', () {
      test('replaces the task with the input data and a network constraint', () async {
        final result = await repository.scheduleOnce(
          'task',
          delay: const Duration(hours: 1),
          requiresNetwork: true,
          replace: true,
        );

        expect(result, const Result<void>.ok(null));
        final captured = verify(
          () => service.registerOneOff(
            'task',
            delay: const Duration(hours: 1),
            inputData: _inputData,
            constraints: captureAny(named: 'constraints'),
            policy: ExistingWorkPolicy.replace,
          ),
        ).captured;
        expect((captured.single as Constraints).networkType, NetworkType.connected);
      });

      test('keeps pending work and needs no network when asked', () async {
        await repository.scheduleOnce('task', delay: Duration.zero, requiresNetwork: false, replace: false);

        final captured = verify(
          () => service.registerOneOff(
            'task',
            delay: Duration.zero,
            inputData: _inputData,
            constraints: captureAny(named: 'constraints'),
            policy: ExistingWorkPolicy.keep,
          ),
        ).captured;
        expect((captured.single as Constraints).networkType, NetworkType.notRequired);
      });

      test('returns a platform error when registering fails', () async {
        when(registerOneOff).thenThrow(PlatformException(code: 'register'));

        expect(
          await repository.scheduleOnce('task', delay: Duration.zero, requiresNetwork: true, replace: true),
          const Result<void>.err(BackgroundTaskPlatformError()),
        );
      });

      test('returns a platform error when the plugin is missing', () async {
        when(registerOneOff).thenThrow(MissingPluginException());

        expect(
          await repository.scheduleOnce('task', delay: Duration.zero, requiresNetwork: true, replace: true),
          const Result<void>.err(BackgroundTaskPlatformError()),
        );
      });
    });

    test('sends empty input data by default', () async {
      await BackgroundTaskRepositoryImpl(service)
          .scheduleOnce('task', delay: Duration.zero, requiresNetwork: true, replace: true);

      verify(
        () => service.registerOneOff(
          'task',
          delay: Duration.zero,
          inputData: const {},
          constraints: any(named: 'constraints'),
          policy: ExistingWorkPolicy.replace,
        ),
      ).called(1);
    });
  });
}
