import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:insaeng/data/services/notion_service.dart';

NotionService _service(Future<Response> Function(Request request) handler) => NotionService(MockClient(handler));

Future<Map<String, Object?>> _query(NotionService service) =>
    service.queryDataSource('secret', 'ds-1', const {'page_size': 10});

void main() {
  group(NotionService, () {
    group('queryDataSource', () {
      test('posts the body to the data source query endpoint with the auth and version headers', () async {
        late Request sent;
        final service = _service((request) async {
          sent = request;
          return Response('{"results": []}', 200);
        });

        await _query(service);

        expect(sent.method, 'POST');
        expect(sent.url, Uri.parse('https://api.notion.com/v1/data_sources/ds-1/query'));
        expect(sent.headers['Authorization'], 'Bearer secret');
        expect(sent.headers['Notion-Version'], NotionService.version);
        expect(sent.headers['Content-Type'], startsWith('application/json'));
        expect(jsonDecode(sent.body), {'page_size': 10});
      });

      test('returns the decoded JSON on success', () async {
        final service = _service((_) async => Response('{"object": "list", "results": [{"id": "p1"}]}', 200));

        expect(await _query(service), {
          'object': 'list',
          'results': [
            {'id': 'p1'},
          ],
        });
      });

      test('throws unauthorized on 401', () {
        final service = _service((_) async => Response('{"code": "unauthorized"}', 401));

        expect(_query(service), throwsA(isA<NotionUnauthorizedException>()));
      });

      test('throws rate limited with the retry delay on 429', () {
        final service = _service((_) async => Response('{}', 429, headers: {'retry-after': '3'}));

        expect(
          _query(service),
          throwsA(
            isA<NotionRateLimitedException>().having((e) => e.retryAfter, 'retryAfter', const Duration(seconds: 3)),
          ),
        );
      });

      test('throws rate limited without a retry delay when the header is missing', () {
        final service = _service((_) async => Response('{}', 429));

        expect(
          _query(service),
          throwsA(isA<NotionRateLimitedException>().having((e) => e.retryAfter, 'retryAfter', isNull)),
        );
      });

      test('throws an http exception with the status and body on other non-2xx responses', () {
        final service = _service((_) async => Response('{"code": "object_not_found"}', 404));

        expect(
          _query(service),
          throwsA(
            isA<NotionHttpException>()
                .having((e) => e.statusCode, 'statusCode', 404)
                .having((e) => e.body, 'body', '{"code": "object_not_found"}'),
          ),
        );
      });

      test('throws a network exception when the request fails', () {
        final failure = ClientException('Connection refused');
        final service = _service((_) async => throw failure);

        expect(_query(service), throwsA(isA<NotionNetworkException>().having((e) => e.cause, 'cause', failure)));
      });

      test('throws a format exception when the response is not a JSON object', () {
        final service = _service((_) async => Response('[1]', 200));

        expect(_query(service), throwsFormatException);
      });
    });
  });
}
