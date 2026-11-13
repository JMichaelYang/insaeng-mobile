import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/data/services/generic_page_fixture_service.dart';

final class _FakeAssetBundle extends CachingAssetBundle {
  new(this._assets);

  final Map<String, String> _assets;

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage({for (final path in _assets.keys) path: <Object?>[]})!;
    }
    final asset = _assets[key];
    if (asset == null) throw StateError('Missing asset $key');
    return ByteData.sublistView(utf8.encode(asset));
  }
}

GenericPageFixtureService _service(Map<String, String> assets) => GenericPageFixtureService(_FakeAssetBundle(assets));

void main() {
  group(GenericPageFixtureService, () {
    test('reads the fixture for the page id', () async {
      final service = _service({'assets/generic_ui/home.json': '{"id": "home", "state": {"count": 0}}'});

      expect(await service.fetchPage('home'), {
        'id': 'home',
        'state': {'count': 0},
      });
    });

    test('throws not found when no fixture has the page id', () {
      final service = _service({'assets/generic_ui/home.json': '{"id": "home"}'});

      expect(
        service.fetchPage('settings'),
        throwsA(isA<GenericPageFixtureNotFoundException>().having((e) => e.id, 'id', 'settings')),
      );
    });

    test('throws a format exception for malformed JSON', () {
      final service = _service({'assets/generic_ui/home.json': '{"id": '});

      expect(service.fetchPage('home'), throwsFormatException);
    });

    test('throws a format exception when the JSON is not an object', () {
      final service = _service({'assets/generic_ui/home.json': '[1]'});

      expect(service.fetchPage('home'), throwsFormatException);
    });
  });
}
