import 'package:insaeng/domain/models/home_widget/widget_snapshot_resolver.dart';
import 'package:insaeng/domain/repositories/generic_page_repository.dart';
import 'package:insaeng/domain/repositories/widget_snapshot_repository.dart';
import 'package:insaeng/domain/result.dart';

class RefreshHomeWidgetUseCase {
  new(this._pages, this._snapshots);

  final GenericPageRepository _pages;
  final WidgetSnapshotRepository _snapshots;

  Future<Result<void>> call(String pageId) async {
    switch (await _pages.fetch(pageId, const {})) {
      case Err(:final failure):
        return Result.err(failure);
      case Ok(value: final page):
        final values = page.initialState;
        final snapshot = WidgetSnapshotResolver.resolve(page, values);
        return switch (await _snapshots.save(snapshot, page: page, values: values)) {
          Err(:final failure) => Result.err(failure),
          Ok() => await _snapshots.update(),
        };
    }
  }
}
