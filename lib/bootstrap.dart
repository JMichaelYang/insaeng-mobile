import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:insaeng/app.dart';
import 'package:insaeng/config/dependencies.dart';
import 'package:insaeng/config/flavor.dart';

Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  LicenseRegistry.addLicense(_fontLicenses);

  configureDependencies(flavor);

  runApp(App(router: getIt<GoRouter>()));
}

Stream<LicenseEntry> _fontLicenses() async* {
  final license = await rootBundle.loadString(
    'assets/fonts/pretendard/LICENSE.txt',
  );
  yield LicenseEntryWithLineBreaks(const ['Pretendard'], license);
}
