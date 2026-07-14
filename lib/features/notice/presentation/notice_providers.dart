import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woncheon_youth/features/notice/data/notice_repository.dart';
import 'package:woncheon_youth/features/notice/domain/notice_model.dart';
import 'package:woncheon_youth/shared/providers/providers.dart';

final noticeRepositoryProvider = Provider<NoticeRepository>((ref) {
  return NoticeRepository(ref.watch(apiClientProvider));
});

final noticeListProvider =
    AsyncNotifierProvider<NoticeListNotifier, NoticeListResponse>(
      NoticeListNotifier.new,
    );

class NoticeListNotifier extends AsyncNotifier<NoticeListResponse> {
  @override
  Future<NoticeListResponse> build() async {
    final repo = ref.watch(noticeRepositoryProvider);
    return repo.listNotices();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final noticeDetailProvider = FutureProvider.autoDispose
    .family<NoticeDetail, String>((ref, noticeId) async {
      final repo = ref.watch(noticeRepositoryProvider);
      return repo.getNotice(noticeId);
    });
