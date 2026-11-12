import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:insaeng/config/flavor.dart';
import 'package:insaeng/routing/router.dart';
import 'package:insaeng/ui/home/view_models/home_cubit.dart';

final GetIt getIt = GetIt.instance;

void configureDependencies(Flavor flavor) {
  getIt
    ..registerSingleton<Flavor>(flavor)
    ..registerFactory<HomeCubit>(HomeCubit.new)
    ..registerLazySingleton<GoRouter>(() => router(getIt));
}
