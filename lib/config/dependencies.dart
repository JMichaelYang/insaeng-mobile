import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:insaeng/config/flavor.dart';
import 'package:insaeng/routing/router.dart';

final GetIt getIt = GetIt.instance;

void configureDependencies(Flavor flavor) {
  getIt
    ..registerSingleton<Flavor>(flavor)
    ..registerLazySingleton<GoRouter>(() => router(getIt));
}
