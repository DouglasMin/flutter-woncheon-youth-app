import 'package:fluentui_system_icons/fluentui_system_icons.dart';
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
    final listState = ref.read(prayerListProvider).valueOrNull;
    final isBusy =
        listState == null || listState.isLoadingMore || listState.isRefreshing;
    if (isBusy) return;
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

    final unread =
        state.valueOrNull?.items
            .where((p) => !readIds.contains(p.prayerId))
            .length ??
        0;

    final listContent = state.when(
      loading: () => const WCLoadingView(label: '기도제목을 불러오는 중'),
      error: (_, __) => WCStateView(
        icon: FluentIcons.error_circle_24_regular,
        title: '기도제목을 불러올 수 없습니다',
        message: '네트워크 상태를 확인한 뒤 다시 시도해주세요.',
        actionLabel: '다시 시도',
        onAction: () => ref.read(prayerListProvider.notifier).refresh(),
      ),
      data: (data) {
        if (data.items.isEmpty) {
          return const WCStateView(
            icon: FluentIcons.hand_left_24_regular,
            title: '아직 올라온 기도가 없어요',
            message: '첫 번째 기도제목을 나눠주세요.',
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(prayerListProvider.notifier).refresh(),
          color: wc.accent,
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(
              WCSpacing.pageX,
              0,
              WCSpacing.pageX,
              WCSpacing.bottomNavClearance,
            ),
            itemCount: data.items.length + (data.isLoadingMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: WCSpacing.xs),
            itemBuilder: (context, index) {
              if (index == data.items.length) {
                return const WCLoadingView(compact: true);
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
                WCHeader(
                  title: '중보기도',
                  subtitle: '함께 기도해요',
                  trailing: unread > 0
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '새 글 $unread',
                            style: TextStyle(
                              fontSize: 13,
                              color: wc.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : null,
                  padding: const EdgeInsets.fromLTRB(
                    WCSpacing.pageX,
                    WCSpacing.xl,
                    WCSpacing.pageX,
                    WCSpacing.sm,
                  ),
                ),
                const PrayerFilterBar(),
                const SizedBox(height: WCSpacing.xs),
                Expanded(child: listContent),
              ],
            ),
          ),
          Positioned(
            right: WCSpacing.pageX,
            bottom: WCSpacing.xl + MediaQuery.of(context).padding.bottom,
            child: _ComposeFab(onPressed: _openCompose),
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
    return Semantics(
      button: true,
      label: '기도 작성',
      child: Material(
        color: wc.text,
        shape: const CircleBorder(),
        shadowColor: Colors.black.withValues(alpha: 0.18),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(FluentIcons.edit_24_regular, size: 24, color: wc.bg),
          ),
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
      density: WCCardDensity.compact,
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
              if (dateStr.isNotEmpty) ...[
                const SizedBox(width: WCSpacing.xs),
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 11.5, color: wc.textTer),
                ),
              ],
              const Spacer(),
              if (!isRead) const UnreadDot(),
            ],
          ),
          const SizedBox(height: WCSpacing.xs),
          Text(
            contentPreview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: isAnonymous ? wc.anonText : wc.textSec,
              height: 1.5,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
