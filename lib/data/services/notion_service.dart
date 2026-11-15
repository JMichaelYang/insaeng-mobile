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
  const new(this._client);

  static final Uri baseUri = Uri.parse('https://api.notion.com/v1/');
  static const version = '2026-03-11';

  final Client _client;

  Future<Map<String, Object?>> queryDataSource(String token, String dataSourceId, Map<String, Object?> body) =>
      _post(token, 'data_sources/${Uri.encodeComponent(dataSourceId)}/query', body);

  Future<Map<String, Object?>> _post(String token, String path, Map<String, Object?> body) async {
    final Response response;
    try {
      response = await _client.post(
        baseUri.resolve(path),
        headers: {'Authorization': 'Bearer $token', 'Notion-Version': version, 'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    } on ClientException catch (e) {
      throw NotionNetworkException(e);
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
