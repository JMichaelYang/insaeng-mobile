import 'package:insaeng/config/dependencies.dart';
import 'package:insaeng/config/flavor.dart';
import 'package:insaeng/data/repositories/my_day_page_mapper.dart';
import 'package:insaeng/data/services/background_task_service.dart';
import 'package:insaeng/domain/use_cases/refresh_home_widget_use_case.dart';
import 'package:insaeng/domain/use_cases/schedule_home_widget_refresh_use_case.dart';
import 'package:workmanager/workmanager.dart';

const backgroundFlavorKey = 'flavor';

@pragma('vm:entry-point')
void backgroundTaskDispatcher() => BackgroundTaskService(Workmanager()).executeTask(runBackgroundTask);

Future<bool> runBackgroundTask(String task, Map<String, dynamic>? inputData) async {
  if (!getIt.isRegistered<Flavor>()) {
    configureDependencies(Flavor.values.asNameMap()[inputData?[backgroundFlavorKey]] ?? Flavor.prod);
  }
  switch (task) {
    case ScheduleHomeWidgetRefreshUseCase.periodicTask:
      await getIt<RefreshHomeWidgetUseCase>()(MyDayPageMapper.widgetPageId);
      await getIt<ScheduleHomeWidgetRefreshUseCase>()(replace: false);
    case ScheduleHomeWidgetRefreshUseCase.midnightTask:
      await getIt<RefreshHomeWidgetUseCase>()(MyDayPageMapper.widgetPageId);
  }
  return true;
}
