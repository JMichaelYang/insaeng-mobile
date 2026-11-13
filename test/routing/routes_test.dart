import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/routing/routes.dart';

void main() {
  group(Routes, () {
    group('pageLocation', () {
      test('maps the home page to the root', () {
        expect(Routes.pageLocation(Routes.homePageId), Routes.home);
      });

      test('keeps params on the home page', () {
        expect(Routes.pageLocation(Routes.homePageId, const {'tab': 'all'}), '/?tab=all');
      });

      test('builds a page path with encoded query params', () {
        expect(Routes.pageLocation('detail', const {'id': '7', 'q': 'a&b'}), '/p/detail?id=7&q=a%26b');
      });

      test('encodes the page id as one path segment', () {
        expect(Routes.pageLocation('a b/c'), '/p/a%20b%2Fc');
      });
    });
  });
}
