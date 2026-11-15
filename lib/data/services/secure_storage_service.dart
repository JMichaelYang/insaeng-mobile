import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  const new(this._storage);

  static const notionTokenKey = 'notion_token';
  static const notionDataSourceIdKey = 'notion_data_source_id';

  final FlutterSecureStorage _storage;

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  Future<void> delete(String key) => _storage.delete(key: key);
}
