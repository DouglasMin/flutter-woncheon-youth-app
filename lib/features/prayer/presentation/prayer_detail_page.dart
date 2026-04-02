import 'package:dio/dio.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:woncheon_youth/core/mock/mock_mode.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/features/prayer/presentation/prayer_providers.dart';
import 'package:woncheon_youth/shared/widgets/adaptive.dart';

class PrayerDetailPage extends ConsumerWidget {
  const PrayerDetailPage({required this.prayerId, super.key});

  final String prayerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mark as read
    ref.listen(prayerDetailProvider(prayerId), (_, next) {
      if (next.hasValue) {
        ref.read(readPrayersStorageProvider).markAsRead(prayerId);
        ref.invalidate(readPrayerIdsProvider);
      }
    });

    final detailAsync = ref.watch(prayerDetailProvider(prayerId));

    final content = detailAsync.when(
      loading: () => Center(
        child: isIOS
            ? const CupertinoActivityIndicator(radius: 14)
            : const CircularProgressIndicator(),
      ),
      error: (_, __) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                FluentIcons.error_circle_24_regular,
                size: 36,
                color: AppColors.error.withAlpha(150),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '오류가 발생했습니다',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(prayerDetailProvider(prayerId)),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
      data: (prayer) {
        final date = DateTime.tryParse(prayer.createdAt);
        final dateStr = date != null
            ? DateFormat('yyyy.M.d (E) HH:mm', 'ko').format(date.toLocal())
            : '';
        final initial = prayer.authorName.isEmpty ? '?' : prayer.authorName[0];
        final avatarColors = prayer.isAnonymous
            ? [AppColors.textTertiary, const Color(0xFFB0B8C4)]
            : [AppColors.primaryDark, AppColors.primary];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(6),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: avatarColors),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prayer.authorName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (prayer.isMine)
                      IconButton(
                        icon: const Icon(
                          FluentIcons.delete_24_regular,
                          color: AppColors.error,
                          size: 20,
                        ),
                        onPressed: () =>
                            _confirmDelete(context, ref, prayer.prayerId),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Content
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(6),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  prayer.content,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.8,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text(
            '중보기도',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppTheme.cupertino.barBackgroundColor,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(child: content),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('중보기도')),
      body: content,
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    await Haptic.medium();

    final confirmed = await showAdaptiveConfirmDialog(
      context,
      title: '삭제',
      content: '이 중보기도를 삭제하시겠습니까?',
      confirmText: '삭제',
      isDestructive: true,
    );

    if (confirmed != true || !context.mounted) return;

    try {
      if (kMockMode) {
        final mockRepo = ref.read(mockPrayerRepositoryProvider);
        await mockRepo.deletePrayer(id);
      } else {
        final repo = ref.read(prayerRepositoryProvider);
        await repo.deletePrayer(id);
      }
      await Haptic.light();
      ref.invalidate(prayerDetailProvider(id));
      await ref.read(prayerListProvider.notifier).refresh();
      if (context.mounted) context.pop();
    } on DioException {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('삭제에 실패했습니다.')));
      }
    }
  }
}
