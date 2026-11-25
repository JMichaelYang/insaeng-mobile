import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/config/dependencies.dart';
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
import 'package:insaeng/ui/home_widget/home_widget_event_handler.dart';
import 'package:workmanager/workmanager.dart';

void main() {
  group(configureDependencies, () {
    tearDown(getIt.reset);

    for (final flavor in Flavor.values) {
      test('registers ${flavor.name} as the flavor', () {
        configureDependencies(flavor);

        expect(getIt<Flavor>(), flavor);
      });

      test('registers the Notion page repository for ${flavor.name}', () {
        configureDependencies(flavor);

        expect(getIt<GenericPageRepository>(), isA<GenericNotionPageRepositoryImpl>());
      });

      test('registers the Notion service for ${flavor.name}', () {
        configureDependencies(flavor);

        expect(getIt<NotionService>(), isA<NotionService>());
      });

      test('registers the Notion service with persistent connections by default for ${flavor.name}', () {
        configureDependencies(flavor);

        expect(getIt<NotionService>().persistentConnection, isTrue);
      });

      test('registers the Notion service without persistent connections in the background for ${flavor.name}', () {
        configureDependencies(flavor, background: true);

        expect(getIt<NotionService>().persistentConnection, isFalse);
      });

      test('registers the secure storage service for ${flavor.name}', () {
        configureDependencies(flavor);

        expect(getIt<SecureStorageService>(), isA<SecureStorageService>());
      });

      test('registers the Notion action repository for ${flavor.name}', () {
        configureDependencies(flavor);

        expect(getIt<GenericActionRepository>(), isA<GenericNotionActionRepositoryImpl>());
      });

      test('registers the home widget service for ${flavor.name}', () {
        configureDependencies(flavor);

        expect(getIt<HomeWidgetService>(), isA<HomeWidgetService>());
      });

      test('registers the widget snapshot repository for ${flavor.name}', () {
        configureDependencies(flavor);

        expect(getIt<WidgetSnapshotRepository>(), isA<WidgetSnapshotRepositoryImpl>());
      });

      test('registers the refresh home widget use case for ${flavor.name}', () {
        configureDependencies(flavor);

        expect(getIt<RefreshHomeWidgetUseCase>(), isA<RefreshHomeWidgetUseCase>());
      });

      test('registers workmanager for ${flavor.name}', () {
        configureDependencies(flavor);

        expect(getIt<Workmanager>(), same(Workmanager()));
      });

      test('registers the background task service for ${flavor.name}', () {
        configureDependencies(flavor);

        expect(getIt<BackgroundTaskService>(), isA<BackgroundTaskService>());
      });

      test('registers the background task repository for ${flavor.name}', () {
        configureDependencies(flavor);

        expect(getIt<BackgroundTaskRepository>(), isA<BackgroundTaskRepositoryImpl>());
      });

      test('registers the schedule home widget refresh use case for ${flavor.name}', () {
        configureDependencies(flavor);

        expect(getIt<ScheduleHomeWidgetRefreshUseCase>(), isA<ScheduleHomeWidgetRefreshUseCase>());
      });

      test('registers one home widget event handler for ${flavor.name}', () {
        configureDependencies(flavor);

        expect(getIt<HomeWidgetEventHandler>(), same(getIt<HomeWidgetEventHandler>()));
      });
    }
  });
}
