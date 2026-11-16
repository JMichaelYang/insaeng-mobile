import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:insaeng/app.dart';
import 'package:insaeng/config/dependencies.dart';
import 'package:insaeng/config/flavor.dart';
import 'package:insaeng/config/widget_refresh_scheduler.dart';
import 'package:insaeng/data/repositories/my_day_page_mapper.dart';
import 'package:insaeng/domain/use_cases/refresh_home_widget_use_case.dart';

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
  if (defaultTargetPlatform == TargetPlatform.android) unawaited(getIt<WidgetRefreshScheduler>().start());

  runApp(App(router: getIt<GoRouter>()));
}

void _refreshHomeWidget() => unawaited(getIt<RefreshHomeWidgetUseCase>()(MyDayPageMapper.widgetPageId));

Stream<LicenseEntry> _fontLicenses() async* {
  final license = await rootBundle.loadString('assets/fonts/pretendard/LICENSE.txt');
  yield LicenseEntryWithLineBreaks(const ['Pretendard'], license);
}
