import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woncheon_youth/features/member/data/block_repository.dart';
import 'package:woncheon_youth/features/member/domain/blocked_member.dart';
import 'package:woncheon_youth/shared/providers/providers.dart';

final blockRepositoryProvider = Provider<BlockRepository>((ref) {
  return BlockRepository(ref.watch(apiClientProvider));
});

/// 현재 로그인한 사용자의 차단 목록.
///
/// - 초기값: secureStorage (login 시 세팅됨). 따라서 로그인 직후 invalidate
///   해주면 최신값으로 리로드됨.
/// - block/unblock: 서버 호출 성공 후 state + storage 동시 갱신.
/// - 동시 호출 방지: 단일 `_inflight` lock으로 직렬화.
final blocklistProvider =
    AsyncNotifierProvider<BlocklistNotifier, List<BlockedMember>>(
  BlocklistNotifier.new,
);

class BlocklistNotifier extends AsyncNotifier<List<BlockedMember>> {
  // 진행 중인 요청. 두 번째 요청은 앞 요청이 끝날 때까지 대기.
  Future<void>? _inflight;

  @override
  Future<List<BlockedMember>> build() async {
    final storage = ref.read(secureStorageServiceProvider);
    return storage.getBlockedMembers();
  }

  /// 편의 getter — 특정 memberId가 차단되어 있는지.
  /// 로딩/에러 상태일 땐 false.
  bool isBlocked(String memberId) {
    final list = state.valueOrNull ?? const [];
    return list.any((b) => b.memberId == memberId);
  }

  Future<void> block(String targetMemberId) async {
    await _serialize(() async {
      final repo = ref.read(blockRepositoryProvider);
      final storage = ref.read(secureStorageServiceProvider);
      final updated = await repo.block(targetMemberId);
      await storage.setBlockedMembers(updated);
      state = AsyncData(updated);
    });
  }

  Future<void> unblock(String targetMemberId) async {
    await _serialize(() async {
      final repo = ref.read(blockRepositoryProvider);
      final storage = ref.read(secureStorageServiceProvider);
      final updated = await repo.unblock(targetMemberId);
      await storage.setBlockedMembers(updated);
      state = AsyncData(updated);
    });
  }

  Future<void> _serialize(Future<void> Function() action) async {
    // 앞 요청이 있으면 완료(또는 에러)까지 대기 → 순차 실행
    final previous = _inflight;
    if (previous != null) {
      try {
        await previous;
      } on Object {
        // 앞 요청의 에러는 삼킴 — 내 요청은 독립적으로 시도
      }
    }
    final future = action();
    _inflight = future;
    try {
      await future;
    } finally {
      if (identical(_inflight, future)) _inflight = null;
    }
  }
}
