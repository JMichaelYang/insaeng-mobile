import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_page.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/domain/models/home_widget/widget_snapshot.dart';
import 'package:insaeng/domain/models/home_widget/widget_snapshot_resolver.dart';
import 'package:insaeng/domain/repositories/generic_page_repository.dart';
import 'package:insaeng/domain/repositories/widget_snapshot_repository.dart';
import 'package:insaeng/domain/result.dart';
import 'package:insaeng/domain/use_cases/refresh_home_widget_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockGenericPageRepository extends Mock implements GenericPageRepository;

class _MockWidgetSnapshotRepository extends Mock implements WidgetSnapshotRepository;

const String _pageId = 'myDayWidget';

final GenericPage _page = GenericPage(
  id: _pageId,
  root: const TextNode(id: 'title', text: Binding('title')),
  state: GenericValues(const {'title': 'My Day'}),
);

void main() {
  group(RefreshHomeWidgetUseCase, () {
    late GenericPageRepository pages;
    late WidgetSnapshotRepository snapshots;
    late RefreshHomeWidgetUseCase useCase;

    setUpAll(() {
      registerFallbackValue(
        const WidgetSnapshot(
          pageId: _pageId,
          root: WidgetNode(type: 'column', id: 'root'),
        ),
      );
      registerFallbackValue(_page);
      registerFallbackValue(GenericValues.empty);
    });

    setUp(() {
      pages = _MockGenericPageRepository();
      snapshots = _MockWidgetSnapshotRepository();
      useCase = RefreshHomeWidgetUseCase(pages, snapshots);
      when(() => pages.fetch(any(), any())).thenAnswer((_) async => Result.ok(_page));
      when(
        () => snapshots.save(
          any(),
          page: any(named: 'page'),
          values: any(named: 'values'),
        ),
      ).thenAnswer((_) async => const Result.ok(null));
      when(() => snapshots.update()).thenAnswer((_) async => const Result.ok(null));
    });

    test('fetches the page with empty params, saves the resolved snapshot, and updates the widget', () async {
      expect(await useCase(_pageId), const Result<void>.ok(null));

      verifyInOrder([
        () => pages.fetch(_pageId, const {}),
        () => snapshots.save(
          WidgetSnapshotResolver.resolve(_page, _page.initialState),
          page: _page,
          values: _page.initialState,
        ),
        () => snapshots.update(),
      ]);
    });

    test('returns the fetch failure without saving or updating', () async {
      when(() => pages.fetch(any(), any())).thenAnswer((_) async => const Result.err(GenericPageOffline()));

      expect(await useCase(_pageId), const Result<void>.err(GenericPageOffline()));
      verifyNever(
        () => snapshots.save(
          any(),
          page: any(named: 'page'),
          values: any(named: 'values'),
        ),
      );
      verifyNever(() => snapshots.update());
    });

    test('returns the save failure without updating', () async {
      when(
        () => snapshots.save(
          any(),
          page: any(named: 'page'),
          values: any(named: 'values'),
        ),
      ).thenAnswer((_) async => const Result.err(WidgetSnapshotPlatformError()));

      expect(await useCase(_pageId), const Result<void>.err(WidgetSnapshotPlatformError()));
      verifyNever(() => snapshots.update());
    });

    test('returns the update failure', () async {
      when(() => snapshots.update()).thenAnswer((_) async => const Result.err(WidgetSnapshotPlatformError()));

      expect(await useCase(_pageId), const Result<void>.err(WidgetSnapshotPlatformError()));
    });
  });
}
