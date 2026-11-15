import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart';
import 'package:insaeng/config/flavor.dart';
import 'package:insaeng/data/repositories/generic_notion_action_repository_impl.dart';
import 'package:insaeng/data/repositories/generic_notion_page_repository_impl.dart';
import 'package:insaeng/data/services/notion_service.dart';
import 'package:insaeng/data/services/secure_storage_service.dart';
import 'package:insaeng/domain/repositories/generic_action_repository.dart';
import 'package:insaeng/domain/repositories/generic_page_repository.dart';
import 'package:insaeng/routing/router.dart';

final GetIt getIt = GetIt.instance;

void configureDependencies(Flavor flavor) {
  getIt
    ..registerSingleton<Flavor>(flavor)
    ..registerLazySingleton<Client>(Client.new)
    ..registerLazySingleton(() => const FlutterSecureStorage())
    ..registerLazySingleton(() => NotionService(getIt()))
    ..registerLazySingleton(() => SecureStorageService(getIt()))
    ..registerLazySingleton<GenericActionRepository>(() => GenericNotionActionRepositoryImpl(getIt(), getIt()))
    ..registerLazySingleton<GenericPageRepository>(() => GenericNotionPageRepositoryImpl(getIt(), getIt()))
    ..registerLazySingleton<GoRouter>(() => router(getIt));
}
