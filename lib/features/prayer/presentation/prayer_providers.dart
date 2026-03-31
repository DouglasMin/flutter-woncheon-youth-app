import 'package:flutter/foundation.dart' show immutable, listEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woncheon_youth/core/mock/mock_mode.dart';
import 'package:woncheon_youth/core/mock/mock_prayer_repository.dart';
import 'package:woncheon_youth/core/storage/read_prayers_storage.dart';
import 'package:woncheon_youth/features/prayer/data/prayer_repository.dart';
import 'package:woncheon_youth/features/prayer/domain/prayer_filter.dart';
import 'package:woncheon_youth/features/prayer/domain/prayer_model.dart';
import 'package:woncheon_youth/shared/providers/providers.dart';

final prayerRepositoryProvider = Provider<PrayerRepository>((ref) {
  return PrayerRepository(ref.watch(apiClientProvider));
});

final mockPrayerRepositoryProvider = Provider<MockPrayerRepository>((ref) {
  return MockPrayerRepository();
});

final prayerFilterProvider =
    StateProvider<PrayerFilter>((ref) => const PrayerFilter());

final readPrayersStorageProvider = Provider<ReadPrayersStorage>((ref) {
  return ReadPrayersStorage();
});

/// Set of read prayer IDs — refreshed when detail page marks one as read.
final readPrayerIdsProvider = FutureProvider<Set<String>>((ref) async {
  final storage = ref.watch(readPrayersStorageProvider);
  return storage.getReadIds();
});

final prayerDetailProvider =
    FutureProvider.family<PrayerDetail, String>((ref, prayerId) async {
  if (kMockMode) {
    final mockRepo = ref.watch(mockPrayerRepositoryProvider);
    return mockRepo.getPrayer(prayerId);
  }
  final repo = ref.watch(prayerRepositoryProvider);
  return repo.getPrayer(prayerId);
});

final prayerListProvider =
    AsyncNotifierProvider<PrayerListNotifier, PrayerListState>(
  PrayerListNotifier.new,
);

@immutable
class PrayerListState {
  const PrayerListState({
    this.items = const [],
    this.nextCursor,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  final List<PrayerItem> items;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoadingMore;

  PrayerListState copyWith({
    List<PrayerItem>? items,
    String? nextCursor,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return PrayerListState(
      items: items ?? this.items,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrayerListState &&
          runtimeType == other.runtimeType &&
          hasMore == other.hasMore &&
          isLoadingMore == other.isLoadingMore &&
          nextCursor == other.nextCursor &&
          listEquals(items, other.items);

  @override
  int get hashCode => Object.hash(
        hasMore,
        isLoadingMore,
        nextCursor,
        Object.hashAll(items),
      );
}

class PrayerListNotifier extends AsyncNotifier<PrayerListState> {
  @override
  Future<PrayerListState> build() async {
    final filter = ref.watch(prayerFilterProvider);
    final startDate = filter.startDate;
    final endDate = filter.endDate;

    late final PrayerListResponse response;
    if (kMockMode) {
      final mockRepo = ref.watch(mockPrayerRepositoryProvider);
      response = await mockRepo.listPrayers(
        startDate: startDate,
        endDate: endDate,
      );
    } else {
      final repo = ref.watch(prayerRepositoryProvider);
      response = await repo.listPrayers(
        startDate: startDate?.toUtc().toIso8601String(),
        endDate: endDate?.toUtc().toIso8601String(),
      );
    }
    return PrayerListState(
      items: response.items,
      nextCursor: response.nextCursor,
      hasMore: response.hasMore,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    final filter = ref.read(prayerFilterProvider);
    final startDate = filter.startDate;
    final endDate = filter.endDate;

    late final PrayerListResponse response;
    if (kMockMode) {
      final mockRepo = ref.read(mockPrayerRepositoryProvider);
      response = await mockRepo.listPrayers(
        cursor: current.nextCursor,
        startDate: startDate,
        endDate: endDate,
      );
    } else {
      final repo = ref.read(prayerRepositoryProvider);
      response = await repo.listPrayers(
        cursor: current.nextCursor,
        startDate: startDate?.toUtc().toIso8601String(),
        endDate: endDate?.toUtc().toIso8601String(),
      );
    }

    state = AsyncData(
      current.copyWith(
        items: [...current.items, ...response.items],
        nextCursor: response.nextCursor,
        hasMore: response.hasMore,
        isLoadingMore: false,
      ),
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
