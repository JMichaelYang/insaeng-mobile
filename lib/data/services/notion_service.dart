import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';

sealed class NotionException implements Exception {
  const new();
}

final class NotionUnauthorizedException extends NotionException {
  const new();

  @override
  String toString() => 'NotionUnauthorizedException()';
}

final class NotionRateLimitedException extends NotionException {
  const new({this.retryAfter});

  final Duration? retryAfter;

  @override
  String toString() => 'NotionRateLimitedException(retryAfter: $retryAfter)';
}

final class NotionHttpException extends NotionException {
  const new(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'NotionHttpException($statusCode, $body)';
}

final class NotionNetworkException extends NotionException {
  const new(this.cause);

  final Object cause;

  @override
  String toString() => 'NotionNetworkException($cause)';
}

class NotionService {
  const new(this._client, {this.timeout = defaultTimeout, this.persistentConnection = true});

  static final Uri baseUri = Uri.parse('https://api.notion.com/v1/');
  static const version = '2026-03-11';
  static const defaultTimeout = Duration(seconds: 15);

  final Client _client;
  final Duration timeout;
  final bool persistentConnection;

  Future<Map<String, Object?>> queryDataSource(String token, String dataSourceId, Map<String, Object?> body) =>
      _send('POST', token, 'data_sources/${Uri.encodeComponent(dataSourceId)}/query', body);

  Future<Map<String, Object?>> updatePage(String token, String pageId, Map<String, Object?> properties) =>
      _send('PATCH', token, 'pages/${Uri.encodeComponent(pageId)}', {'properties': properties});

  Future<Map<String, Object?>> _send(String method, String token, String path, Map<String, Object?> body) async {
    final abort = Completer<void>();
    final timer = Timer(timeout, abort.complete);
    final request = AbortableRequest(method, baseUri.resolve(path), abortTrigger: abort.future)
      ..persistentConnection = persistentConnection
      ..headers.addAll({
        'Authorization': 'Bearer $token',
        'Notion-Version': version,
        'Content-Type': 'application/json',
      })
      ..body = jsonEncode(body);
    final Response response;
    try {
      response = await Response.fromStream(await _client.send(request));
    } on ClientException catch (e) {
      throw NotionNetworkException(e);
    } finally {
      timer.cancel();
    }
    return switch (response.statusCode) {
      >= 200 && < 300 => _decode(response),
      401 => throw const NotionUnauthorizedException(),
      429 => throw NotionRateLimitedException(retryAfter: _retryAfter(response)),
      final status => throw NotionHttpException(status, response.body),
    };
  }

  Map<String, Object?> _decode(Response response) => switch (jsonDecode(response.body)) {
    final Map<String, Object?> json => json,
    final other => throw FormatException('Expected a JSON object', other),
  };

  Duration? _retryAfter(Response response) => switch (int.tryParse(response.headers['retry-after'] ?? '')) {
    final int seconds => Duration(seconds: seconds),
    null => null,
  };
}
