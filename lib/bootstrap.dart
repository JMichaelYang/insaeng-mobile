import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:insaeng/app.dart';
import 'package:insaeng/config/dependencies.dart';
import 'package:insaeng/config/flavor.dart';
import 'package:insaeng/data/repositories/my_day_page_mapper.dart';
import 'package:insaeng/data/services/background_task_service.dart';
import 'package:insaeng/domain/use_cases/refresh_home_widget_use_case.dart';
import 'package:insaeng/domain/use_cases/schedule_home_widget_refresh_use_case.dart';
import 'package:workmanager/workmanager.dart';

Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  LicenseRegistry.addLicense(_fontLicenses);

  configureDependencies(flavor);

  _refreshHomeWidget();
  AppLifecycleListener(onPause: _refreshHomeWidget);
  unawaited(_scheduleHomeWidgetRefresh());

  runApp(App(router: getIt<GoRouter>()));
}

void bootstrapBackground(Flavor flavor) {
  if (!getIt.isRegistered<Flavor>()) configureDependencies(flavor);
}

@pragma('vm:entry-point')
void backgroundTaskDispatcher() => BackgroundTaskService(Workmanager()).executeTask(runBackgroundTask);

Future<bool> runBackgroundTask(String task, Map<String, dynamic>? inputData) async {
  bootstrapBackground(Flavor.values.asNameMap()[inputData?[backgroundFlavorKey]] ?? Flavor.prod);
  switch (task) {
    case ScheduleHomeWidgetRefreshUseCase.periodicTask:
      await getIt<RefreshHomeWidgetUseCase>()(MyDayPageMapper.widgetPageId);
      await getIt<ScheduleHomeWidgetRefreshUseCase>()(replace: false);
    case ScheduleHomeWidgetRefreshUseCase.midnightTask:
      await getIt<RefreshHomeWidgetUseCase>()(MyDayPageMapper.widgetPageId);
  }
  return true;
}

void _refreshHomeWidget() => unawaited(getIt<RefreshHomeWidgetUseCase>()(MyDayPageMapper.widgetPageId));

Future<void> _scheduleHomeWidgetRefresh() async {
  if (defaultTargetPlatform != TargetPlatform.android) return;
  await getIt<BackgroundTaskService>().initialize(backgroundTaskDispatcher);
  await getIt<ScheduleHomeWidgetRefreshUseCase>()(replace: true);
}

Stream<LicenseEntry> _fontLicenses() async* {
  final license = await rootBundle.loadString('assets/fonts/pretendard/LICENSE.txt');
  yield LicenseEntryWithLineBreaks(const ['Pretendard'], license);
}
