import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/features/notice/presentation/notice_providers.dart';
import 'package:woncheon_youth/shared/widgets/adaptive.dart';
import 'package:woncheon_youth/shared/widgets/wc_widgets.dart';

class NoticeDetailPage extends ConsumerWidget {
  const NoticeDetailPage({required this.noticeId, super.key});

  final String noticeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wc = context.wc;
    final detailAsync = ref.watch(noticeDetailProvider(noticeId));

    return Scaffold(
      backgroundColor: wc.bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: wc.border, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
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
            ),
            Expanded(
              child: detailAsync.when(
                loading: () => Center(
                  child: isIOS
                      ? const CupertinoActivityIndicator(radius: 14)
                      : CircularProgressIndicator(color: wc.accent),
                ),
                error: (_, __) => WCStateView(
                  icon: FluentIcons.error_circle_24_regular,
                  title: '공지사항을 불러올 수 없습니다',
                  message: '삭제되었거나 게시가 중지된 공지일 수 있습니다.',
                  actionLabel: '다시 시도',
                  onAction: () =>
                      ref.invalidate(noticeDetailProvider(noticeId)),
                ),
                data: (notice) {
                  final date = DateTime.tryParse(notice.publishedAt);
                  final dateLabel = date != null ? formatRelative(date) : '';

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      WCSpacing.pageX,
                      WCSpacing.lg,
                      WCSpacing.pageX,
                      48,
                    ),
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
                            if (dateLabel.isNotEmpty)
                              Text(
                                dateLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: wc.textTer,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: WCSpacing.sm),
                        Text(
                          notice.title,
                          style: TextStyle(
                            fontSize: 24,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                            color: wc.text,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: WCSpacing.lg),
                        WCCard(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                          child: Text(
                            notice.content,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.75,
                              color: wc.text,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
