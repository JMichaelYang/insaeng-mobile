import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/bootstrap.dart';
import 'package:insaeng/config/dependencies.dart';
import 'package:insaeng/config/flavor.dart';
import 'package:insaeng/data/services/notion_service.dart';
import 'package:insaeng/data/services/widget_event_service.dart';
import 'package:insaeng/domain/repositories/background_task_repository.dart';
import 'package:insaeng/domain/result.dart';
import 'package:insaeng/domain/use_cases/refresh_home_widget_use_case.dart';
import 'package:insaeng/domain/use_cases/schedule_home_widget_refresh_use_case.dart';
import 'package:insaeng/ui/home_widget/home_widget_event_handler.dart';
import 'package:mocktail/mocktail.dart';

class _MockRefreshHomeWidgetUseCase extends Mock implements RefreshHomeWidgetUseCase;

class _MockScheduleHomeWidgetRefreshUseCase extends Mock implements ScheduleHomeWidgetRefreshUseCase;

class _MockHomeWidgetEventHandler extends Mock implements HomeWidgetEventHandler;

void main() {
  tearDown(getIt.reset);

  group(bootstrapBackground, () {
    for (final flavor in Flavor.values) {
      test('configures dependencies for ${flavor.name}', () {
        bootstrapBackground(flavor);

        expect(getIt<Flavor>(), flavor);
        expect(getIt<RefreshHomeWidgetUseCase>(), isA<RefreshHomeWidgetUseCase>());
      });
    }

    test('configures the Notion service without persistent connections', () {
      bootstrapBackground(Flavor.prod);

      expect(getIt<NotionService>().persistentConnection, isFalse);
    });

    test('keeps dependencies that are already configured', () {
      bootstrapBackground(Flavor.dev);
      bootstrapBackground(Flavor.prod);

      expect(getIt<Flavor>(), Flavor.dev);
    });
  });

  group(runBackgroundTask, () {
    late RefreshHomeWidgetUseCase refresh;
    late ScheduleHomeWidgetRefreshUseCase schedule;

    setUp(() {
      refresh = _MockRefreshHomeWidgetUseCase();
      schedule = _MockScheduleHomeWidgetRefreshUseCase();
      when(() => refresh(any())).thenAnswer((_) async => const Result.ok(null));
      when(() => schedule(replace: any(named: 'replace'))).thenAnswer((_) async => const Result.ok(null));
      getIt
        ..registerSingleton(Flavor.dev)
        ..registerSingleton(refresh)
        ..registerSingleton(schedule);
    });

    test('refreshes the widget and keeps the schedule for the periodic task', () async {
      expect(await runBackgroundTask(ScheduleHomeWidgetRefreshUseCase.periodicTask, null), isTrue);

      verify(() => refresh('myDayWidget')).called(1);
      verify(() => schedule(replace: false)).called(1);
    });

    test('refreshes the widget without rescheduling for the midnight task', () async {
      expect(await runBackgroundTask(ScheduleHomeWidgetRefreshUseCase.midnightTask, null), isTrue);

      verify(() => refresh('myDayWidget')).called(1);
      verifyNever(() => schedule(replace: any(named: 'replace')));
    });

    test('succeeds when the refresh and schedule fail', () async {
      when(() => refresh(any())).thenAnswer((_) async => const Result.err(BackgroundTaskPlatformError()));
      when(() => schedule(replace: any(named: 'replace')))
          .thenAnswer((_) async => const Result.err(BackgroundTaskPlatformError()));

      expect(await runBackgroundTask(ScheduleHomeWidgetRefreshUseCase.periodicTask, null), isTrue);
    });

    test('ignores unknown tasks', () async {
      expect(await runBackgroundTask('unknown', null), isTrue);

      verifyNever(() => refresh(any()));
      verifyNever(() => schedule(replace: any(named: 'replace')));
    });

    test('keeps dependencies that are already configured', () async {
      await runBackgroundTask(ScheduleHomeWidgetRefreshUseCase.midnightTask, {backgroundFlavorKey: 'prod'});

      expect(getIt<Flavor>(), Flavor.dev);
    });
  });

  group(homeWidgetEventDispatcher, () {
    late HomeWidgetEventHandler handler;

    setUp(() {
      handler = _MockHomeWidgetEventHandler();
      when(() => handler.handle(any())).thenAnswer((_) async {});
    });

    test('forwards the URI to the event handler', () async {
      getIt
        ..registerSingleton(Flavor.dev)
        ..registerSingleton(handler);
      final uri = Uri.parse('insaeng://widget/event?flavor=dev&page=myDayWidget&node=task-a&event=onChanged');

      await homeWidgetEventDispatcher(uri);

      verify(() => handler.handle(uri)).called(1);
    });

    for (final flavor in Flavor.values) {
      test('configures dependencies for the ${flavor.name} flavor in the URI', () async {
        await homeWidgetEventDispatcher(Uri.parse('insaeng://widget/event?flavor=${flavor.name}'));

        expect(getIt<Flavor>(), flavor);
      });
    }

    test('falls back to prod without a flavor', () async {
      await homeWidgetEventDispatcher(null);

      expect(getIt<Flavor>(), Flavor.prod);
    });
  });

  group(widgetEventMain, () {
    const channel = WidgetEventService.channel;
    late HomeWidgetEventHandler handler;
    late Completer<void> ready;

    TestDefaultBinaryMessenger messenger() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      handler = _MockHomeWidgetEventHandler();
      when(() => handler.handle(any())).thenAnswer((_) async {});
      getIt
        ..registerSingleton(Flavor.dev)
        ..registerSingleton(handler);
      ready = Completer<void>();
      messenger().setMockMethodCallHandler(channel, (call) async {
        if (call.method == WidgetEventService.readyMethod) ready.complete();
        return null;
      });
    });

    tearDown(() {
      messenger().setMockMethodCallHandler(channel, null);
      channel.setMethodCallHandler(null);
    });

    test('hands widget events from the platform to the event handler', () async {
      const uri = 'insaeng://widget/event?flavor=dev&page=myDayWidget&node=refresh&event=onTap';

      widgetEventMain();
      await ready.future;
      final reply = Completer<ByteData?>();
      await messenger().handlePlatformMessage(
        channel.name,
        channel.codec.encodeMethodCall(const MethodCall(WidgetEventService.handleMethod, uri)),
        reply.complete,
      );
      await reply.future;

      verify(() => handler.handle(Uri.parse(uri))).called(1);
    });
  });
}
