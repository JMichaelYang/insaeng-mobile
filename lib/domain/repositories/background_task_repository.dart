import 'package:insaeng/domain/result.dart';

sealed class BackgroundTaskFailure extends Failure {
  const new();
}

final class BackgroundTaskPlatformError extends BackgroundTaskFailure {
  const new();
}

abstract interface class BackgroundTaskRepository {
  Future<Result<void>> schedulePeriodic(
    String name, {
    required Duration frequency,
    required bool requiresNetwork,
    required bool replace,
  });

  Future<Result<void>> scheduleOnce(
    String name, {
    required Duration delay,
    required bool requiresNetwork,
    required bool replace,
  });
}
