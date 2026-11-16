import 'package:flutter/services.dart';
import 'package:insaeng/data/services/background_task_service.dart';
import 'package:insaeng/domain/repositories/background_task_repository.dart';
import 'package:insaeng/domain/result.dart';
import 'package:workmanager/workmanager.dart';

final class BackgroundTaskRepositoryImpl implements BackgroundTaskRepository {
  const new(this._service, {this._inputData = const {}});

  final BackgroundTaskService _service;
  final Map<String, dynamic> _inputData;

  @override
  Future<Result<void>> schedulePeriodic(
    String name, {
    required Duration frequency,
    required bool requiresNetwork,
    required bool replace,
  }) => _guard(
    () => _service.registerPeriodic(
      name,
      frequency: frequency,
      inputData: _inputData,
      constraints: _constraints(requiresNetwork: requiresNetwork),
      policy: replace ? ExistingPeriodicWorkPolicy.update : ExistingPeriodicWorkPolicy.keep,
    ),
  );

  @override
  Future<Result<void>> scheduleOnce(
    String name, {
    required Duration delay,
    required bool requiresNetwork,
    required bool replace,
  }) => _guard(
    () => _service.registerOneOff(
      name,
      delay: delay,
      inputData: _inputData,
      constraints: _constraints(requiresNetwork: requiresNetwork),
      policy: replace ? ExistingWorkPolicy.replace : ExistingWorkPolicy.keep,
    ),
  );

  Constraints _constraints({required bool requiresNetwork}) =>
      Constraints(networkType: requiresNetwork ? NetworkType.connected : NetworkType.notRequired);

  Future<Result<void>> _guard(Future<void> Function() body) async {
    try {
      await body();
      return const Result.ok(null);
    } on PlatformException {
      return const Result.err(BackgroundTaskPlatformError());
    } on MissingPluginException {
      return const Result.err(BackgroundTaskPlatformError());
    }
  }
}
