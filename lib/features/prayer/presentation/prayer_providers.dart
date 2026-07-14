import 'package:flutter/foundation.dart' show immutable, listEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woncheon_youth/core/storage/read_prayers_storage.dart';
import 'package:woncheon_youth/features/prayer/data/prayer_repository.dart';
import 'package:woncheon_youth/features/prayer/domain/comment_model.dart';
import 'package:woncheon_youth/features/prayer/domain/prayer_filter.dart';
import 'package:woncheon_youth/features/prayer/domain/prayer_model.dart';
import 'package:woncheon_youth/shared/providers/providers.dart';

final prayerRepositoryProvider = Provider<PrayerRepository>((ref) {
  return PrayerRepository(ref.watch(apiClientProvider));
});

final prayerFilterProvider = StateProvider<PrayerFilter>(
  (ref) => const PrayerFilter(),
);

enum PrayerViewMode { list, card }

final prayerViewModeProvider = StateProvider<PrayerViewMode>(
  (ref) => PrayerViewMode.list,
);

final readPrayersStorageProvider = Provider<ReadPrayersStorage>((ref) {
  return ReadPrayersStorage();
});

/// Set of read prayer IDs — refreshed when detail page marks one as read.
final readPrayerIdsProvider = FutureProvider<Set<String>>((ref) async {
  final storage = ref.watch(readPrayersStorageProvider);
  return storage.getReadIds();
});

// Comments
final commentsProvider = FutureProvider.autoDispose
    .family<List<CommentItem>, String>((ref, prayerId) async {
      final repo = ref.watch(prayerRepositoryProvider);
      return repo.getComments(prayerId);
    });

// Reactions — loaded from server, cached locally
final reactionProvider =
    AsyncNotifierProvider.family<ReactionNotifier, ReactionState, String>(
      ReactionNotifier.new,
    );

class ReactionNotifier extends FamilyAsyncNotifier<ReactionState, String> {
  bool _isToggling = false;

  @override
  Future<ReactionState> build(String prayerId) async {
    final repo = ref.read(prayerRepositoryProvider);
    return repo.getReaction(prayerId);
  }

  Future<void> toggle() async {
    if (_isToggling) return;
    _isToggling = true;

    final previous = state.valueOrNull;
    if (previous != null) {
      state = AsyncData(
        ReactionState(
          reacted: !previous.reacted,
          count: previous.count + (previous.reacted ? -1 : 1),
        ),
      );
    }

    try {
      final repo = ref.read(prayerRepositoryProvider);
      final result = await repo.toggleReaction(arg);
      state = AsyncData(result);
    } catch (error, stackTrace) {
      if (previous != null) state = AsyncData(previous);
      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      _isToggling = false;
    }
  }
}

final prayerDetailProvider = FutureProvider.autoDispose
    .family<PrayerDetail, String>((ref, prayerId) async {
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
    this.isRefreshing = false,
  });

  final List<PrayerItem> items;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isRefreshing;

  PrayerListState copyWith({
    List<PrayerItem>? items,
    String? nextCursor,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isRefreshing,
  }) {
    return PrayerListState(
      items: items ?? this.items,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrayerListState &&
          runtimeType == other.runtimeType &&
          hasMore == other.hasMore &&
          isLoadingMore == other.isLoadingMore &&
          isRefreshing == other.isRefreshing &&
          nextCursor == other.nextCursor &&
          listEquals(items, other.items);

  @override
  int get hashCode => Object.hash(
    hasMore,
    isLoadingMore,
    isRefreshing,
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

    final repo = ref.watch(prayerRepositoryProvider);
    final response = await repo.listPrayers(
      startDate: startDate?.toUtc().toIso8601String(),
      endDate: endDate?.toUtc().toIso8601String(),
    );
    return PrayerListState(
      items: response.items,
      nextCursor: response.nextCursor,
      hasMore: response.hasMore,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null ||
        !current.hasMore ||
        current.isLoadingMore ||
        current.isRefreshing) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true));

    final filter = ref.read(prayerFilterProvider);
    final startDate = filter.startDate;
    final endDate = filter.endDate;

    final repo = ref.read(prayerRepositoryProvider);
    final response = await repo.listPrayers(
      cursor: current.nextCursor,
      startDate: startDate?.toUtc().toIso8601String(),
      endDate: endDate?.toUtc().toIso8601String(),
    );

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
    final current = state.valueOrNull;
    if (current == null) {
      ref.invalidateSelf();
      await future;
      return;
    }

    state = AsyncData(current.copyWith(isRefreshing: true));

    final filter = ref.read(prayerFilterProvider);
    final startDate = filter.startDate;
    final endDate = filter.endDate;
    final repo = ref.read(prayerRepositoryProvider);

    try {
      final response = await repo.listPrayers(
        startDate: startDate?.toUtc().toIso8601String(),
        endDate: endDate?.toUtc().toIso8601String(),
      );

      state = AsyncData(
        PrayerListState(
          items: response.items,
          nextCursor: response.nextCursor,
          hasMore: response.hasMore,
        ),
      );
    } on Object {
      state = AsyncData(current.copyWith(isRefreshing: false));
      rethrow;
    }
  }
}
