import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _directive = RegExp(
  r'''^\s*(?:import|export|part)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

final Uri _lib = Directory('lib').absolute.uri;

typedef _Rule = ({String layer, List<String> forbidden});

const List<_Rule> _rules = [
  (
    layer: 'domain/',
    forbidden: [
      'dart:ui',
      'package:flutter/',
      'package:material_ui/',
      'package:cupertino_ui/',
      'lib/data/',
      'lib/ui/',
      'lib/utils/',
      'lib/routing/',
      'lib/config/',
      'lib/l10n/',
      'lib/app.dart',
      'lib/bootstrap.dart',
    ],
  ),
  (
    layer: 'data/',
    forbidden: [
      'lib/ui/',
      'lib/routing/',
      'lib/config/',
      'lib/app.dart',
      'lib/bootstrap.dart',
    ],
  ),
  (layer: 'ui/', forbidden: ['lib/data/', 'lib/config/']),
  (
    layer: 'utils/',
    forbidden: ['lib/data/', 'lib/ui/', 'lib/routing/', 'lib/config/'],
  ),
];

String _target(File file, String uri) {
  if (uri.startsWith('package:insaeng/')) {
    return 'lib/${uri.substring('package:insaeng/'.length)}';
  }
  if (uri.startsWith('package:') || uri.startsWith('dart:')) return uri;
  final resolved = file.absolute.uri.resolve(uri).toString();
  return resolved.startsWith(_lib.toString())
      ? 'lib/${resolved.substring(_lib.toString().length)}'
      : resolved;
}

List<String> _violations(_Rule rule) {
  final dir = Directory('lib/${rule.layer}');
  if (!dir.existsSync()) return const [];
  return [
    for (final file in dir.listSync(recursive: true).whereType<File>())
      if (file.path.endsWith('.dart'))
        for (final match in _directive.allMatches(file.readAsStringSync()))
          if (_target(file, match.group(1)!) case final target
              when rule.forbidden.any(target.startsWith))
            '${file.path} -> $target',
  ];
}

void main() {
  group('layer boundaries', () {
    for (final rule in _rules) {
      test('lib/${rule.layer} respects its forbidden imports', () {
        expect(_violations(rule), isEmpty);
      });
    }
  });
}
