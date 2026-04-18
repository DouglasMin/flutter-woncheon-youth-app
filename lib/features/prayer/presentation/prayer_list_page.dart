import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woncheon_youth/core/router/app_router.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/features/prayer/presentation/prayer_filter_bar.dart';
import 'package:woncheon_youth/features/prayer/presentation/prayer_providers.dart';
import 'package:woncheon_youth/shared/widgets/adaptive.dart';
import 'package:woncheon_youth/shared/widgets/wc_widgets.dart';

class PrayerListPage extends ConsumerStatefulWidget {
  const PrayerListPage({super.key});

  @override
  ConsumerState<PrayerListPage> createState() => _PrayerListPageState();
}

class _PrayerListPageState extends ConsumerState<PrayerListPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final isLoading =
        ref.read(prayerListProvider).valueOrNull?.isLoadingMore ?? false;
    if (isLoading) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(prayerListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    final state = ref.watch(prayerListProvider);
    final readIds = ref.watch(readPrayerIdsProvider).valueOrNull ?? {};

    final unread = state.valueOrNull?.items
            .where((p) => !readIds.contains(p.prayerId))
            .length ??
        0;

    final listContent = state.when(
      loading: () => Center(
        child: isIOS
            ? const CupertinoActivityIndicator(radius: 14)
            : const CircularProgressIndicator(),
      ),
      error: (_, __) => _ListErrorView(
        onRetry: () => ref.read(prayerListProvider.notifier).refresh(),
      ),
      data: (data) {
        if (data.items.isEmpty) return const _ListEmptyView();
        return RefreshIndicator(
          onRefresh: () => ref.read(prayerListProvider.notifier).refresh(),
          color: wc.accent,
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
            itemCount: data.items.length + (data.isLoadingMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == data.items.length) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: isIOS
                        ? const CupertinoActivityIndicator()
                        : const CircularProgressIndicator(),
                  ),
                );
              }
              final item = data.items[index];
              final date = DateTime.tryParse(item.createdAt);
              return _PrayerCard(
                authorName: item.authorName,
                contentPreview: item.contentPreview,
                date: date,
                isAnonymous: item.isAnonymous,
                isRead: readIds.contains(item.prayerId),
                onTap: () {
                  Haptic.selection();
                  context.push(AppRoutes.prayerDetail(item.prayerId));
                },
              );
            },
          ),
        );
      },
    );

    return Scaffold(
      backgroundColor: wc.bg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '중보기도',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: wc.text,
                          letterSpacing: -0.7,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (unread > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '· 새 글 $unread',
                            style: TextStyle(
                              fontSize: 13,
                              color: wc.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Text(
                    '함께 기도해요',
                    style: TextStyle(fontSize: 13, color: wc.textTer),
                  ),
                ),
                const PrayerFilterBar(),
                const SizedBox(height: 8),
                Expanded(child: listContent),
              ],
            ),
          ),
          Positioned(
            right: 20,
            bottom: 28 + MediaQuery.of(context).padding.bottom,
            child: _ComposeFab(
              onPressed: _openCompose,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCompose() async {
    await Haptic.light();
    if (!mounted) return;
    final result = await context.push<bool>(AppRoutes.prayerCreate);
    if ((result ?? false) && mounted) {
      await ref.read(prayerListProvider.notifier).refresh();
    }
  }
}

class _ComposeFab extends StatelessWidget {
  const _ComposeFab({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: wc.text,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          FluentIcons.edit_24_regular,
          size: 24,
          color: wc.bg,
        ),
      ),
    );
  }
}

class _ListErrorView extends StatelessWidget {
  const _ListErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.error_circle_24_regular,
            size: 36,
            color: wc.textTer,
          ),
          const SizedBox(height: 12),
          Text(
            '오류가 발생했습니다',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: wc.text,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: Text(
              '다시 시도',
              style: TextStyle(color: wc.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListEmptyView extends StatelessWidget {
  const _ListEmptyView();

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🕊️', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              '아직 올라온 기도가 없어요',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: wc.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '첫 번째로 나눠주세요',
              style: TextStyle(fontSize: 13, color: wc.textTer),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerCard extends StatelessWidget {
  const _PrayerCard({
    required this.authorName,
    required this.contentPreview,
    required this.date,
    required this.isAnonymous,
    required this.isRead,
    required this.onTap,
  });

  final String authorName;
  final String contentPreview;
  final DateTime? date;
  final bool isAnonymous;
  final bool isRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    final dateStr = date != null ? formatRelative(date!) : '';

    return WCCard(
      anon: isAnonymous,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isAnonymous)
                const AnonPill(small: true)
              else
                Text(
                  authorName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: wc.text,
                    letterSpacing: -0.3,
                  ),
                ),
              const SizedBox(width: 6),
              Text(
                '· $dateStr',
                style: TextStyle(fontSize: 11.5, color: wc.textTer),
              ),
              const Spacer(),
              if (!isRead) const UnreadDot(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            contentPreview,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.5,
              color: isAnonymous ? wc.anonText : wc.textSec,
              height: 1.6,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
