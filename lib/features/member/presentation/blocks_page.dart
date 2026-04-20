import 'package:dio/dio.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/features/member/domain/blocked_member.dart';
import 'package:woncheon_youth/features/member/presentation/block_providers.dart';
import 'package:woncheon_youth/features/prayer/presentation/prayer_providers.dart';
import 'package:woncheon_youth/shared/widgets/adaptive.dart';

class BlocksPage extends ConsumerWidget {
  const BlocksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wc = context.wc;
    final asyncBlocks = ref.watch(blocklistProvider);

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
                      '차단 관리',
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
              child: asyncBlocks.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Text(
                    '차단 목록을 불러올 수 없습니다.',
                    style: TextStyle(color: wc.textSec),
                  ),
                ),
                data: (blocks) {
                  if (blocks.isEmpty) return _EmptyView();
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: blocks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _BlockedRow(member: blocks[i]),
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

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FluentIcons.person_prohibited_24_regular,
              size: 40,
              color: wc.textTer,
            ),
            const SizedBox(height: 12),
            Text(
              '차단한 사용자가 없어요',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: wc.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '기도 상세에서 "이 사용자 차단"을 누르면 여기에 표시됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: wc.textTer, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockedRow extends ConsumerStatefulWidget {
  const _BlockedRow({required this.member});
  final BlockedMember member;

  @override
  ConsumerState<_BlockedRow> createState() => _BlockedRowState();
}

class _BlockedRowState extends ConsumerState<_BlockedRow> {
  bool _loading = false;

  Future<void> _unblock() async {
    if (_loading) return;
    final member = widget.member;
    final confirmed = await showAdaptiveConfirmDialog(
      context,
      title: '${member.memberName} 님 차단 해제',
      content: '차단을 해제하면 이 사용자의 기도/댓글이 다시 보입니다.',
      confirmText: '해제',
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(blocklistProvider.notifier)
          .unblock(member.memberId);
      if (!mounted) return;
      ref.invalidate(prayerListProvider);
      // commentsProvider는 family — 어느 prayer detail이 열릴지 모르니 family 전체 무효화
      ref.invalidate(commentsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${member.memberName} 님 차단을 해제했습니다.')),
      );
    } on DioException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('차단 해제에 실패했습니다.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: wc.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: wc.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: wc.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              widget.member.memberName.isEmpty
                  ? '?'
                  : widget.member.memberName.characters.first,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: wc.textSec,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.member.memberName,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: wc.text,
              ),
            ),
          ),
          TextButton(
            onPressed: _loading ? null : _unblock,
            style: TextButton.styleFrom(
              foregroundColor: wc.accent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: _loading
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: wc.accent,
                    ),
                  )
                : const Text(
                    '해제',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }
}
