import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:insaeng/routing/router.dart';
import 'package:insaeng/ui/home/view_models/home_cubit.dart';

final GetIt getIt = GetIt.instance;

void configureDependencies() {
  getIt
    ..registerFactory<HomeCubit>(HomeCubit.new)
    ..registerLazySingleton<GoRouter>(() => router(getIt));
}
