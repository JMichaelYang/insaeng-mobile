import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:insaeng/routing/router.dart';
import 'package:insaeng/ui/home/view_models/home_cubit.dart';

final GetIt getIt = GetIt.instance;

/// Registers the app's dependencies. Wired by hand: services and
/// repositories as lazy singletons, view models as factories.
void configureDependencies() {
  getIt
    // View models
    ..registerFactory<HomeCubit>(HomeCubit.new)
    // Routing
    ..registerLazySingleton<GoRouter>(() => router(getIt));
}
