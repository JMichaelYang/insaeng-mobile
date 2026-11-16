import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart';
import 'package:insaeng/config/flavor.dart';
import 'package:insaeng/data/repositories/background_task_repository_impl.dart';
import 'package:insaeng/data/repositories/generic_notion_action_repository_impl.dart';
import 'package:insaeng/data/repositories/generic_notion_page_repository_impl.dart';
import 'package:insaeng/data/repositories/widget_snapshot_repository_impl.dart';
import 'package:insaeng/data/services/background_task_service.dart';
import 'package:insaeng/data/services/home_widget_service.dart';
import 'package:insaeng/data/services/notion_service.dart';
import 'package:insaeng/data/services/secure_storage_service.dart';
import 'package:insaeng/domain/repositories/background_task_repository.dart';
import 'package:insaeng/domain/repositories/generic_action_repository.dart';
import 'package:insaeng/domain/repositories/generic_page_repository.dart';
import 'package:insaeng/domain/repositories/widget_snapshot_repository.dart';
import 'package:insaeng/domain/use_cases/refresh_home_widget_use_case.dart';
import 'package:insaeng/domain/use_cases/schedule_home_widget_refresh_use_case.dart';
import 'package:insaeng/routing/router.dart';
import 'package:workmanager/workmanager.dart';

final GetIt getIt = GetIt.instance;

const backgroundFlavorKey = 'flavor';

void configureDependencies(Flavor flavor) {
  getIt
    ..registerSingleton<Flavor>(flavor)
    ..registerLazySingleton<Client>(Client.new)
    ..registerLazySingleton(() => const FlutterSecureStorage())
    ..registerLazySingleton(Workmanager.new)
    ..registerLazySingleton(() => BackgroundTaskService(getIt()))
    ..registerLazySingleton(() => const HomeWidgetService())
    ..registerLazySingleton(() => NotionService(getIt()))
    ..registerLazySingleton(() => SecureStorageService(getIt()))
    ..registerLazySingleton<BackgroundTaskRepository>(
      () => BackgroundTaskRepositoryImpl(getIt(), inputData: {backgroundFlavorKey: flavor.name}),
    )
    ..registerLazySingleton<GenericActionRepository>(() => GenericNotionActionRepositoryImpl(getIt(), getIt()))
    ..registerLazySingleton<GenericPageRepository>(() => GenericNotionPageRepositoryImpl(getIt(), getIt()))
    ..registerLazySingleton<WidgetSnapshotRepository>(() => WidgetSnapshotRepositoryImpl(getIt()))
    ..registerLazySingleton(() => RefreshHomeWidgetUseCase(getIt(), getIt()))
    ..registerLazySingleton(() => ScheduleHomeWidgetRefreshUseCase(getIt()))
    ..registerLazySingleton<GoRouter>(() => router(getIt));
}
