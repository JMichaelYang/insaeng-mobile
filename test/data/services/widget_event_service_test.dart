import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/data/services/widget_event_service.dart';

const MethodChannel _channel = WidgetEventService.channel;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(WidgetEventService, () {
    const service = WidgetEventService();
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    late List<MethodCall> calls;

    Future<ByteData?> send(MethodCall call) {
      final reply = Completer<ByteData?>();
      unawaited(messenger.handlePlatformMessage(_channel.name, _channel.codec.encodeMethodCall(call), reply.complete));
      return reply.future;
    }

    setUp(() {
      calls = [];
      messenger.setMockMethodCallHandler(_channel, (call) async {
        calls.add(call);
        return null;
      });
    });

    tearDown(() {
      messenger.setMockMethodCallHandler(_channel, null);
      _channel.setMethodCallHandler(null);
    });

    test('tells the platform it is ready', () async {
      await service.listen((_) {});

      expect(calls.single.method, WidgetEventService.readyMethod);
    });

    test('forwards the event URI to the handler', () async {
      final uris = <Uri?>[];
      await service.listen(uris.add);
      const uri = 'insaeng://widget/event?flavor=prod&page=myDayWidget&node=refresh&event=onTap';

      await send(const MethodCall(WidgetEventService.handleMethod, uri));

      expect(uris, [Uri.parse(uri)]);
    });

    test('replies only after the handler finishes', () async {
      final handled = Completer<void>();
      await service.listen((_) => handled.future);
      var replied = false;

      final reply = send(const MethodCall(WidgetEventService.handleMethod, 'insaeng://widget/event')).then((data) {
        replied = true;
        return data;
      });
      await pumpEventQueue();

      expect(replied, isFalse);
      handled.complete();
      expect(_channel.codec.decodeEnvelope((await reply)!), isNull);
    });

    test('replies with the handler error', () async {
      await service.listen((_) => throw StateError('broken'));

      final reply = await send(const MethodCall(WidgetEventService.handleMethod, 'insaeng://widget/event'));

      expect(() => _channel.codec.decodeEnvelope(reply!), throwsA(isA<PlatformException>()));
    });

    test('rejects unknown methods', () async {
      await service.listen((_) {});

      expect(await send(const MethodCall('unknown')), isNull);
    });
  });
}
