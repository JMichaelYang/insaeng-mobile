import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/data/services/home_widget_service.dart';

const _channel = MethodChannel('home_widget');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(HomeWidgetService, () {
    const service = HomeWidgetService();
    late List<MethodCall> calls;

    void answer(Object? Function(MethodCall call) handler) => TestDefaultBinaryMessengerBinding
        .instance
        .defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          calls.add(call);
          return handler(call);
        });

    setUp(() => calls = []);

    tearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_channel, null),
    );

    group('save', () {
      test('saves the value under the key', () async {
        answer((_) => true);

        expect(await service.save('key', 'value'), isTrue);
        expect(calls.single.method, 'saveWidgetData');
        expect(calls.single.arguments, {'id': 'key', 'data': 'value'});
      });

      test('propagates platform errors', () {
        answer((_) => throw PlatformException(code: 'save'));

        expect(() => service.save('key', 'value'), throwsA(isA<PlatformException>()));
      });
    });

    group('read', () {
      test('returns the stored value for the key', () async {
        answer((_) => 'value');

        expect(await service.read('key'), 'value');
        expect(calls.single.method, 'getWidgetData');
        expect(calls.single.arguments, {'id': 'key', 'defaultValue': null});
      });

      test('returns null when nothing is stored for the key', () async {
        answer((_) => null);

        expect(await service.read('key'), isNull);
      });

      test('propagates platform errors', () {
        answer((_) => throw PlatformException(code: 'read'));

        expect(() => service.read('key'), throwsA(isA<PlatformException>()));
      });
    });

    group('update', () {
      test('updates the generic widget receiver', () async {
        answer((_) => true);

        expect(await service.update(), isTrue);
        expect(calls.single.method, 'updateWidget');
        expect(
          (calls.single.arguments as Map<Object?, Object?>)['qualifiedAndroidName'],
          'com.jae.insaeng.GenericWidgetReceiver',
        );
      });

      test('propagates platform errors', () {
        answer((_) => throw PlatformException(code: 'update'));

        expect(() => service.update(), throwsA(isA<PlatformException>()));
      });
    });
  });
}
