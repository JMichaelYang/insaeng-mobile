import 'package:workmanager/workmanager.dart';

class BackgroundTaskService {
  const new(this._workmanager);

  final Workmanager _workmanager;

  Future<void> initialize(void Function() dispatcher) => _workmanager.initialize(dispatcher);

  void executeTask(BackgroundTaskHandler handler) => _workmanager.executeTask(handler);

  Future<void> registerPeriodic(
    String name, {
    required Duration frequency,
    required Map<String, dynamic> inputData,
    required Constraints constraints,
    required ExistingPeriodicWorkPolicy policy,
  }) => _workmanager.registerPeriodicTask(
    name,
    name,
    frequency: frequency,
    inputData: inputData,
    constraints: constraints,
    existingWorkPolicy: policy,
  );

  Future<void> registerOneOff(
    String name, {
    required Duration delay,
    required Map<String, dynamic> inputData,
    required Constraints constraints,
    required ExistingWorkPolicy policy,
  }) => _workmanager.registerOneOffTask(
    name,
    name,
    initialDelay: delay,
    inputData: inputData,
    constraints: constraints,
    existingWorkPolicy: policy,
  );
}
