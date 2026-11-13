import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:insaeng/config/flavor.dart';
import 'package:insaeng/data/repositories/generic_page_repository_impl.dart';
import 'package:insaeng/data/services/generic_page_fixture_service.dart';
import 'package:insaeng/domain/repositories/generic_page_repository.dart';
import 'package:insaeng/routing/router.dart';

final GetIt getIt = GetIt.instance;

void configureDependencies(Flavor flavor) {
  getIt
    ..registerSingleton<Flavor>(flavor)
    ..registerLazySingleton<AssetBundle>(() => rootBundle)
    ..registerLazySingleton(() => GenericPageFixtureService(getIt()))
    ..registerLazySingleton<GenericPageRepository>(() => GenericPageRepositoryImpl(getIt()))
    ..registerLazySingleton<GoRouter>(() => router(getIt));
}
