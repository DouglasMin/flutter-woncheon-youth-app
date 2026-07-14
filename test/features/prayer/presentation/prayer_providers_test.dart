import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woncheon_youth/core/api/api_client.dart';
import 'package:woncheon_youth/core/constants.dart';
import 'package:woncheon_youth/features/prayer/data/prayer_repository.dart';
import 'package:woncheon_youth/features/prayer/domain/prayer_model.dart';
import 'package:woncheon_youth/features/prayer/presentation/prayer_providers.dart';

void main() {
  test(
    'refresh preserves current prayer list while fetching fresh data',
    () async {
      final refreshCompleter = Completer<PrayerListResponse>();
      final container = ProviderContainer(
        overrides: [
          prayerRepositoryProvider.overrideWithValue(
            _FakePrayerRepository(
              firstItems: [_fakePrayer('P1')],
              refreshedResponse: refreshCompleter.future,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final initial = await container.read(prayerListProvider.future);
      expect(initial.items.map((p) => p.prayerId), ['P1']);

      final refreshFuture = container
          .read(prayerListProvider.notifier)
          .refresh();
      await Future<void>.delayed(Duration.zero);

      final duringRefresh = container.read(prayerListProvider).valueOrNull;
      expect(duringRefresh?.items.map((p) => p.prayerId), ['P1']);
      expect(duringRefresh?.isRefreshing, isTrue);

      refreshCompleter.complete(
        PrayerListResponse(items: [_fakePrayer('P2')], hasMore: false),
      );
      await refreshFuture;

      final refreshed = container.read(prayerListProvider).valueOrNull;
      expect(refreshed?.items.map((p) => p.prayerId), ['P2']);
      expect(refreshed?.isRefreshing, isFalse);
    },
  );

  test('loadMore is ignored while refresh is pending', () async {
    final refreshCompleter = Completer<PrayerListResponse>();
    final repository = _FakePrayerRepository(
      firstItems: [_fakePrayer('P1')],
      refreshedResponse: refreshCompleter.future,
      firstHasMore: true,
      firstNextCursor: 'CURSOR_1',
    );
    final container = ProviderContainer(
      overrides: [prayerRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(prayerListProvider.future);

    final notifier = container.read(prayerListProvider.notifier);
    final refreshFuture = notifier.refresh();
    await Future<void>.delayed(Duration.zero);

    final loadMoreFuture = notifier.loadMore();
    await Future<void>.delayed(Duration.zero);

    expect(repository.calls, 2);

    refreshCompleter.complete(
      PrayerListResponse(items: [_fakePrayer('P2')], hasMore: false),
    );
    await refreshFuture;
    await loadMoreFuture;
  });
}

PrayerItem _fakePrayer(String id) {
  return PrayerItem(
    prayerId: id,
    authorName: '테스터',
    isAnonymous: false,
    contentPreview: '기도제목',
    createdAt: '2026-07-14T00:00:00.000Z',
  );
}

class _FakePrayerRepository extends PrayerRepository {
  _FakePrayerRepository({
    required this.firstItems,
    required this.refreshedResponse,
    this.firstHasMore = false,
    this.firstNextCursor,
  }) : super(ApiClient.forTest());

  final List<PrayerItem> firstItems;
  final Future<PrayerListResponse> refreshedResponse;
  final bool firstHasMore;
  final String? firstNextCursor;
  int calls = 0;

  @override
  Future<PrayerListResponse> listPrayers({
    int limit = AppConstants.defaultPageSize,
    String? cursor,
    String? startDate,
    String? endDate,
    List<String>? memberIds,
  }) async {
    calls += 1;
    if (calls == 1) {
      return PrayerListResponse(
        items: firstItems,
        hasMore: firstHasMore,
        nextCursor: firstNextCursor,
      );
    }
    return refreshedResponse;
  }
}
