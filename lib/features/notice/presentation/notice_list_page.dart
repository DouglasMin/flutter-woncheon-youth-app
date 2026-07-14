import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woncheon_youth/core/router/app_router.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/features/notice/domain/notice_model.dart';
import 'package:woncheon_youth/features/notice/presentation/notice_providers.dart';
import 'package:woncheon_youth/shared/widgets/adaptive.dart';
import 'package:woncheon_youth/shared/widgets/wc_widgets.dart';

class NoticeListPage extends ConsumerWidget {
  const NoticeListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wc = context.wc;
    final state = ref.watch(noticeListProvider);

    final content = state.when(
      loading: () => const WCLoadingView(label: '공지사항을 불러오는 중'),
      error: (_, __) => WCStateView(
        icon: FluentIcons.error_circle_24_regular,
        title: '공지사항을 불러올 수 없습니다',
        message: '네트워크 상태를 확인한 뒤 다시 시도해주세요.',
        actionLabel: '다시 시도',
        onAction: () => ref.read(noticeListProvider.notifier).refresh(),
      ),
      data: (data) {
        if (data.items.isEmpty) {
          return const WCStateView(
            icon: FluentIcons.megaphone_24_regular,
            title: '아직 공지사항이 없어요',
            message: '새 공지가 올라오면 이곳에서 확인할 수 있습니다.',
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(noticeListProvider.notifier).refresh(),
          color: wc.accent,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              WCSpacing.pageX,
              0,
              WCSpacing.pageX,
              48,
            ),
            itemCount: data.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: WCSpacing.xs),
            itemBuilder: (context, index) {
              final notice = data.items[index];
              return NoticeCard(
                notice: notice,
                onTap: () {
                  Haptic.selection();
                  context.push(AppRoutes.noticeDetail(notice.noticeId));
                },
              );
            },
          ),
        );
      },
    );

    return Scaffold(
      backgroundColor: wc.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _NoticeListTopBar(),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}

class _NoticeListTopBar extends StatelessWidget {
  const _NoticeListTopBar();

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: wc.border, width: 0.5)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: '뒤로',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
                return;
              }
              context.go(AppRoutes.home);
            },
            icon: Icon(
              FluentIcons.chevron_left_24_regular,
              color: wc.text,
              size: 24,
            ),
          ),
          Expanded(
            child: Text(
              '공지사항',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: wc.text,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class NoticeCard extends StatelessWidget {
  const NoticeCard({required this.notice, required this.onTap, super.key});

  final NoticeItem notice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    final date = DateTime.tryParse(notice.publishedAt);
    final dateLabel = date != null ? formatRelative(date) : '';

    return WCCard(
      onTap: onTap,
      density: WCCardDensity.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (notice.pinned) ...[
                const WCPill(
                  tone: WCPillTone.accent,
                  small: true,
                  child: Text('고정'),
                ),
                const SizedBox(width: WCSpacing.xs),
              ],
              Expanded(
                child: Text(
                  notice.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: wc.text,
                  ),
                ),
              ),
              if (dateLabel.isNotEmpty) ...[
                const SizedBox(width: WCSpacing.sm),
                Text(
                  dateLabel,
                  style: TextStyle(fontSize: 11.5, color: wc.textTer),
                ),
              ],
            ],
          ),
          const SizedBox(height: WCSpacing.xs),
          Text(
            notice.contentPreview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, color: wc.textSec, height: 1.5),
          ),
        ],
      ),
    );
  }
}
