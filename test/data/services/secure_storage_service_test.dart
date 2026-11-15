import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/data/services/secure_storage_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockFlutterSecureStorage extends Mock implements FlutterSecureStorage;

void main() {
  group(SecureStorageService, () {
    late FlutterSecureStorage storage;
    late SecureStorageService service;

    setUp(() {
      storage = _MockFlutterSecureStorage();
      service = SecureStorageService(storage);
    });

    group('read', () {
      test('returns the stored value for the key', () async {
        when(() => storage.read(key: 'token')).thenAnswer((_) async => 'secret');

        expect(await service.read('token'), 'secret');
      });

      test('returns null when nothing is stored for the key', () async {
        when(() => storage.read(key: 'token')).thenAnswer((_) async => null);

        expect(await service.read('token'), isNull);
      });

      test('propagates storage errors', () {
        when(() => storage.read(key: 'token')).thenThrow(PlatformException(code: 'read'));

        expect(() => service.read('token'), throwsA(isA<PlatformException>()));
      });
    });

    group('write', () {
      test('stores the value under the key', () async {
        when(() => storage.write(key: 'token', value: 'secret')).thenAnswer((_) async {});

        await service.write('token', 'secret');

        verify(() => storage.write(key: 'token', value: 'secret')).called(1);
      });

      test('propagates storage errors', () {
        when(() => storage.write(key: 'token', value: 'secret')).thenThrow(PlatformException(code: 'write'));

        expect(() => service.write('token', 'secret'), throwsA(isA<PlatformException>()));
      });
    });

    group('delete', () {
      test('deletes the value for the key', () async {
        when(() => storage.delete(key: 'token')).thenAnswer((_) async {});

        await service.delete('token');

        verify(() => storage.delete(key: 'token')).called(1);
      });

      test('propagates storage errors', () {
        when(() => storage.delete(key: 'token')).thenThrow(PlatformException(code: 'delete'));

        expect(() => service.delete('token'), throwsA(isA<PlatformException>()));
      });
    });
  });
}
