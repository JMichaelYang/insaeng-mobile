import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/data/services/background_task_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:workmanager/workmanager.dart';

class _MockWorkmanager extends Mock implements Workmanager;

void _dispatcher() {}

Future<bool> _handler(String task, Map<String, dynamic>? inputData) async => true;

void main() {
  group(BackgroundTaskService, () {
    late Workmanager workmanager;
    late BackgroundTaskService service;
    final constraints = Constraints(networkType: NetworkType.connected);

    Future<void> registerPeriodic() => workmanager.registerPeriodicTask(
      any(),
      any(),
      frequency: any(named: 'frequency'),
      inputData: any(named: 'inputData'),
      constraints: any(named: 'constraints'),
      existingWorkPolicy: any(named: 'existingWorkPolicy'),
    );

    Future<void> registerOneOff() => workmanager.registerOneOffTask(
      any(),
      any(),
      initialDelay: any(named: 'initialDelay'),
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
      service = BackgroundTaskService(workmanager);
    });

    group('initialize', () {
      test('initializes workmanager with the dispatcher', () async {
        when(() => workmanager.initialize(any())).thenAnswer((_) async {});

        await service.initialize(_dispatcher);

        verify(() => workmanager.initialize(_dispatcher)).called(1);
      });

      test('propagates platform errors', () {
        when(() => workmanager.initialize(any())).thenThrow(PlatformException(code: 'initialize'));

        expect(() => service.initialize(_dispatcher), throwsA(isA<PlatformException>()));
      });
    });

    group('executeTask', () {
      test('hands the handler to workmanager', () {
        service.executeTask(_handler);

        verify(() => workmanager.executeTask(_handler)).called(1);
      });
    });

    group('registerPeriodic', () {
      test('registers a periodic task named after itself', () async {
        when(registerPeriodic).thenAnswer((_) async {});

        await service.registerPeriodic(
          'task',
          frequency: const Duration(minutes: 15),
          inputData: {'key': 'value'},
          constraints: constraints,
          policy: ExistingPeriodicWorkPolicy.update,
        );

        verify(
          () => workmanager.registerPeriodicTask(
            'task',
            'task',
            frequency: const Duration(minutes: 15),
            inputData: {'key': 'value'},
            constraints: constraints,
            existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
          ),
        ).called(1);
      });

      test('propagates platform errors', () {
        when(registerPeriodic).thenThrow(PlatformException(code: 'register'));

        expect(
          () => service.registerPeriodic(
            'task',
            frequency: Duration.zero,
            inputData: const {},
            constraints: constraints,
            policy: ExistingPeriodicWorkPolicy.keep,
          ),
          throwsA(isA<PlatformException>()),
        );
      });
    });

    group('registerOneOff', () {
      test('registers a delayed one-off task named after itself', () async {
        when(registerOneOff).thenAnswer((_) async {});

        await service.registerOneOff(
          'task',
          delay: const Duration(hours: 1),
          inputData: {'key': 'value'},
          constraints: constraints,
          policy: ExistingWorkPolicy.replace,
        );

        verify(
          () => workmanager.registerOneOffTask(
            'task',
            'task',
            initialDelay: const Duration(hours: 1),
            inputData: {'key': 'value'},
            constraints: constraints,
            existingWorkPolicy: ExistingWorkPolicy.replace,
          ),
        ).called(1);
      });

      test('propagates platform errors', () {
        when(registerOneOff).thenThrow(PlatformException(code: 'register'));

        expect(
          () => service.registerOneOff(
            'task',
            delay: Duration.zero,
            inputData: const {},
            constraints: constraints,
            policy: ExistingWorkPolicy.keep,
          ),
          throwsA(isA<PlatformException>()),
        );
      });
    });
  });
}
