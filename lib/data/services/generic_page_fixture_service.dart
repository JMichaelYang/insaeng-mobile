import 'dart:convert';

import 'package:flutter/services.dart';

final class GenericPageFixtureNotFoundException implements Exception {
  const new(this.id);

  final String id;

  @override
  String toString() => 'GenericPageFixtureNotFoundException($id)';
}

class GenericPageFixtureService {
  const new(this._bundle);

  static const directory = 'assets/generic_ui';

  final AssetBundle _bundle;

  Future<Map<String, Object?>> fetchPage(String id) async {
    final path = '$directory/$id.json';
    final manifest = await AssetManifest.loadFromAssetBundle(_bundle);
    if (!manifest.listAssets().contains(path)) throw GenericPageFixtureNotFoundException(id);
    return switch (jsonDecode(await _bundle.loadString(path))) {
      final Map<String, Object?> json => json,
      final other => throw FormatException('Expected a JSON object', other),
    };
  }
}
