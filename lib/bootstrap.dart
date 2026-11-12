import 'dart:async';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:insaeng/config/dependencies.dart';

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  configureDependencies();

  runApp(await builder());
}
