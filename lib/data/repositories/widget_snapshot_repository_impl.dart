import 'dart:convert';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/services.dart';
import 'package:insaeng/data/services/home_widget_service.dart';
import 'package:insaeng/domain/models/generic_ui/generic_page.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/home_widget/widget_snapshot.dart';
import 'package:insaeng/domain/repositories/widget_snapshot_repository.dart';
import 'package:insaeng/domain/result.dart';

final class WidgetSnapshotRepositoryImpl implements WidgetSnapshotRepository {
  const new(this._service);

  final HomeWidgetService _service;

  static String snapshotKey(String pageId) => 'widget_snapshot_$pageId';

  static String pageKey(String pageId) => 'widget_page_$pageId';

  @override
  Future<Result<void>> save(WidgetSnapshot snapshot, {required GenericPage page, required GenericValues values}) =>
      _guard(() async {
        final pageJson = jsonEncode({'page': page.toMap(), 'values': values.values});
        final saved = [
          await _service.save(snapshotKey(snapshot.pageId), snapshot.toJson()),
          await _service.save(pageKey(snapshot.pageId), pageJson),
        ];
        return saved.contains(false) ? const Result.err(WidgetSnapshotPlatformError()) : const Result.ok(null);
      });

  @override
  Future<Result<WidgetPageState>> load(String pageId) => _guard(() async {
    final raw = await _service.read(pageKey(pageId));
    if (raw == null) return const Result.err(WidgetSnapshotNotFound());
    try {
      return switch (jsonDecode(raw)) {
        {'page': final Map<String, Object?> page, 'values': final Map<String, Object?> values} => Result.ok((
          page: GenericPageMapper.fromMap(page),
          values: GenericValues(values),
        )),
        _ => const Result.err(WidgetSnapshotInvalid()),
      };
    } on FormatException {
      return const Result.err(WidgetSnapshotInvalid());
    } on MapperException {
      return const Result.err(WidgetSnapshotInvalid());
    }
  });

  @override
  Future<Result<void>> update() => _guard(() async {
    final updated = await _service.update();
    return updated == false ? const Result.err(WidgetSnapshotPlatformError()) : const Result.ok(null);
  });

  Future<Result<T>> _guard<T>(Future<Result<T>> Function() body) async {
    try {
      return await body();
    } on PlatformException {
      return const Result.err(WidgetSnapshotPlatformError());
    } on MissingPluginException {
      return const Result.err(WidgetSnapshotPlatformError());
    }
  }
}
