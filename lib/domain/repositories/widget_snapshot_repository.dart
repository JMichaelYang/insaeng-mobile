import 'package:insaeng/domain/models/generic_ui/generic_page.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/home_widget/widget_snapshot.dart';
import 'package:insaeng/domain/result.dart';

sealed class WidgetSnapshotFailure extends Failure {
  const new();
}

final class WidgetSnapshotNotFound extends WidgetSnapshotFailure {
  const new();
}

final class WidgetSnapshotInvalid extends WidgetSnapshotFailure {
  const new();
}

final class WidgetSnapshotPlatformError extends WidgetSnapshotFailure {
  const new();
}

typedef WidgetPageState = ({GenericPage page, GenericValues values});

abstract interface class WidgetSnapshotRepository {
  Future<Result<void>> save(WidgetSnapshot snapshot, {required GenericPage page, required GenericValues values});

  Future<Result<WidgetPageState>> load(String pageId);

  Future<Result<void>> update();
}
