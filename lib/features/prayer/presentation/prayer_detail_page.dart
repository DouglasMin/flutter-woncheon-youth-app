import 'package:dio/dio.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:woncheon_youth/core/mock/mock_mode.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/features/member/presentation/block_providers.dart';
import 'package:woncheon_youth/features/prayer/domain/comment_model.dart';
import 'package:woncheon_youth/features/prayer/presentation/prayer_providers.dart';
import 'package:woncheon_youth/shared/providers/providers.dart';
import 'package:woncheon_youth/shared/widgets/adaptive.dart';
import 'package:woncheon_youth/shared/widgets/report_dialog.dart';
import 'package:woncheon_youth/shared/widgets/wc_widgets.dart';

class PrayerDetailPage extends ConsumerWidget {
  const PrayerDetailPage({required this.prayerId, super.key});

  final String prayerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(prayerDetailProvider(prayerId), (_, next) {
      if (next.hasValue) {
        ref.read(readPrayersStorageProvider).markAsRead(prayerId);
        ref.invalidate(readPrayerIdsProvider);
      }
    });

    final wc = context.wc;
    final detailAsync = ref.watch(prayerDetailProvider(prayerId));

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
                    icon: Icon(FluentIcons.chevron_left_24_regular,
                        color: wc.text, size: 24),
                  ),
                  Expanded(
                    child: Text(
                      '중보기도',
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
                      : const CircularProgressIndicator(),
                ),
                error: (_, __) => _ErrorView(
                  onRetry: () =>
                      ref.invalidate(prayerDetailProvider(prayerId)),
                ),
                data: (prayer) {
                  final date = DateTime.tryParse(prayer.createdAt);
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AuthorMeta(
                          authorName: prayer.authorName,
                          isAnonymous: prayer.isAnonymous,
                          dateStr: date != null ? formatRelative(date) : '',
                          trailing: prayer.isMine
                              ? IconButton(
                                  onPressed: () => _confirmDelete(
                                      context, ref, prayer.prayerId),
                                  icon: Icon(
                                    FluentIcons.delete_24_regular,
                                    color: wc.danger,
                                    size: 18,
                                  ),
                                )
                              : _OtherUserMenu(
                                  prayerId: prayer.prayerId,
                                  authorMemberId: prayer.authorMemberId,
                                  authorName: prayer.authorName,
                                  isAnonymous: prayer.isAnonymous,
                                ),
                        ),
                        const SizedBox(height: 14),
                        WCCard(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                          child: Text(
                            prayer.content,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.75,
                              color: wc.text,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _ReactionRow(prayerId: prayerId),
                        const SizedBox(height: 28),
                        _CommentsSection(prayerId: prayerId),
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
        await ref.read(mockPrayerRepositoryProvider).deletePrayer(id);
      } else {
        await ref.read(prayerRepositoryProvider).deletePrayer(id);
      }
      await Haptic.light();
      ref.invalidate(prayerDetailProvider(id));
      await ref.read(prayerListProvider.notifier).refresh();
      if (context.mounted) context.pop();
    } on DioException {
      if (context.mounted) _showErrorMessage(context, '삭제에 실패했습니다.');
    }
  }
}

class _AuthorMeta extends StatelessWidget {
  const _AuthorMeta({
    required this.authorName,
    required this.isAnonymous,
    required this.dateStr,
    required this.trailing,
  });

  final String authorName;
  final bool isAnonymous;
  final String dateStr;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: isAnonymous ? wc.anon : wc.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAnonymous ? wc.anonBorder : wc.border,
        ),
      ),
      child: Row(
        children: [
          if (isAnonymous)
            Icon(FluentIcons.eye_off_16_regular,
                size: 20, color: wc.anonText)
          else
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: wc.accent,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAnonymous ? '익명' : authorName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isAnonymous ? wc.anonText : wc.text,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  isAnonymous ? '작성자 정보가 보호되는 게시물이에요' : dateStr,
                  style: TextStyle(fontSize: 11.5, color: wc.textTer),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _ReactionRow extends ConsumerWidget {
  const _ReactionRow({required this.prayerId});
  final String prayerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wc = context.wc;
    final asyncState = ref.watch(reactionProvider(prayerId));
    final state =
        asyncState.valueOrNull ?? const ReactionState(reacted: false, count: 0);

    return Row(
      children: [
        PrayButton(
          count: state.count,
          reacted: state.reacted,
          onTap: () async {
            await ref.read(reactionProvider(prayerId).notifier).toggle();
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            state.reacted ? '함께 기도하고 있어요' : '🙏를 눌러 함께 기도해요',
            style: TextStyle(fontSize: 12, color: wc.textTer),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(FluentIcons.error_circle_24_regular,
              size: 36, color: wc.textTer),
          const SizedBox(height: 12),
          Text(
            '오류가 발생했습니다',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: wc.text,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: Text('다시 시도', style: TextStyle(color: wc.accent)),
          ),
        ],
      ),
    );
  }
}

class _CommentsSection extends ConsumerStatefulWidget {
  const _CommentsSection({required this.prayerId});
  final String prayerId;

  @override
  ConsumerState<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<_CommentsSection> {
  final _controller = TextEditingController();
  bool _isSending = false;
  String? _currentMemberId;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    _loadMemberId();
  }

  Future<void> _loadMemberId() async {
    final id =
        await ref.read(secureStorageServiceProvider).getMemberId();
    if (mounted) setState(() => _currentMemberId = id);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;
    setState(() => _isSending = true);
    await Haptic.light();
    try {
      if (!kMockMode) {
        await ref.read(prayerRepositoryProvider).createComment(
              prayerId: widget.prayerId,
              content: content,
            );
      }
      _controller.clear();
      if (mounted) ref.invalidate(commentsProvider(widget.prayerId));
    } on DioException {
      if (mounted) _showErrorMessage(context, '댓글 작성에 실패했습니다.');
    } catch (_) {
      // invalidate can throw after successful API
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _editComment(CommentItem comment) async {
    final editController = TextEditingController(text: comment.content);
    final wc = context.wc;
    final newContent = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('댓글 수정'),
        content: TextField(
          controller: editController,
          maxLines: 3,
          maxLength: 200,
          decoration: const InputDecoration(hintText: '댓글을 수정하세요...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('취소', style: TextStyle(color: wc.textSec)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(editController.text),
            child: Text('수정', style: TextStyle(color: wc.accent)),
          ),
        ],
      ),
    );
    editController.dispose();
    if (newContent == null || newContent.trim().isEmpty || !mounted) return;
    try {
      if (!kMockMode) {
        await ref.read(prayerRepositoryProvider).updateComment(
              prayerId: widget.prayerId,
              commentId: comment.commentId,
              content: newContent.trim(),
            );
        ref.invalidate(commentsProvider(widget.prayerId));
      }
      await Haptic.light();
    } on DioException {
      if (mounted) _showErrorMessage(context, '댓글 수정에 실패했습니다.');
    }
  }

  Future<void> _deleteComment(CommentItem comment) async {
    final confirmed = await showAdaptiveConfirmDialog(
      context,
      title: '댓글 삭제',
      content: '이 댓글을 삭제하시겠습니까?',
      confirmText: '삭제',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;
    try {
      if (!kMockMode) {
        await ref.read(prayerRepositoryProvider).deleteComment(
              prayerId: widget.prayerId,
              commentId: comment.commentId,
            );
        ref.invalidate(commentsProvider(widget.prayerId));
      }
      await Haptic.light();
    } on DioException {
      if (mounted) _showErrorMessage(context, '댓글 삭제에 실패했습니다.');
    }
  }

  void _showActions(CommentItem comment) {
    Haptic.medium();
    if (isIOS) {
      showCupertinoModalPopup<void>(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                _editComment(comment);
              },
              child: const Text('수정'),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(ctx).pop();
                _deleteComment(comment);
              },
              child: const Text('삭제'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
        ),
      );
    } else {
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(FluentIcons.edit_24_regular),
                title: const Text('수정'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _editComment(comment);
                },
              ),
              ListTile(
                leading: Icon(FluentIcons.delete_24_regular,
                    color: context.wc.danger),
                title: Text('삭제',
                    style: TextStyle(color: context.wc.danger)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _deleteComment(comment);
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    final commentsAsync = ref.watch(commentsProvider(widget.prayerId));
    final hasText = _controller.text.trim().isNotEmpty;
    final count = commentsAsync.valueOrNull?.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '댓글 $count',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: wc.textSec,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submit(),
                style: TextStyle(color: wc.text, fontSize: 14),
                decoration: InputDecoration(
                  hintText: '따뜻한 말 한 마디…',
                  filled: true,
                  fillColor: wc.surface,
                  hintStyle: TextStyle(color: wc.textTer, fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: wc.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: wc.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: wc.accent, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: (_isSending || !hasText) ? null : _submit,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: hasText ? wc.accent : wc.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isSending
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: wc.bg,
                        ),
                      )
                    : Icon(
                        FluentIcons.send_24_regular,
                        size: 18,
                        color: hasText ? wc.bg : wc.textTer,
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        commentsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => Text(
            '댓글을 불러올 수 없습니다.',
            style: TextStyle(color: wc.textTer, fontSize: 13),
          ),
          data: (comments) {
            if (comments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '아직 댓글이 없습니다.',
                  style: TextStyle(color: wc.textTer, fontSize: 13),
                ),
              );
            }
            return Column(
              children: [
                for (final c in comments) ...[
                  _CommentTile(
                    comment: c,
                    isMine: _currentMemberId != null &&
                        c.memberId == _currentMemberId,
                    onLongPress: () => _showActions(c),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.isMine,
    required this.onLongPress,
  });

  final CommentItem comment;
  final bool isMine;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    final date = DateTime.tryParse(comment.createdAt);
    final dateStr = date != null
        ? DateFormat('M/d HH:mm', 'ko').format(date.toLocal())
        : '';

    return GestureDetector(
      onLongPress: isMine ? onLongPress : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: wc.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: wc.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  comment.authorName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: wc.text,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '· $dateStr',
                  style: TextStyle(fontSize: 11, color: wc.textTer),
                ),
                const Spacer(),
                if (isMine) const WCPill(small: true, child: Text('내 댓글')),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              comment.content,
              style: TextStyle(
                fontSize: 14,
                color: wc.textSec,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtherUserMenu extends ConsumerWidget {
  const _OtherUserMenu({
    required this.prayerId,
    required this.authorMemberId,
    required this.authorName,
    required this.isAnonymous,
  });

  final String prayerId;
  final String? authorMemberId;
  final String authorName;
  final bool isAnonymous;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wc = context.wc;
    return PopupMenuButton<String>(
      icon: Icon(
        FluentIcons.more_horizontal_24_regular,
        color: wc.textTer,
        size: 20,
      ),
      tooltip: '옵션',
      onSelected: (value) async {
        switch (value) {
          case 'report':
            await showReportDialog(
              context: context,
              apiClient: ref.read(apiClientProvider),
              targetType: 'prayer',
              targetId: prayerId,
            );
          case 'block':
            await _handleBlock(context, ref);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              Icon(FluentIcons.flag_24_regular, size: 18, color: wc.textSec),
              const SizedBox(width: 10),
              const Text('신고'),
            ],
          ),
        ),
        // 익명 게시물에는 차단 메뉴 숨김 (누가 썼는지 모름)
        if (!isAnonymous && authorMemberId != null)
          PopupMenuItem(
            value: 'block',
            child: Row(
              children: [
                Icon(
                  FluentIcons.person_prohibited_24_regular,
                  size: 18,
                  color: wc.danger,
                ),
                const SizedBox(width: 10),
                Text(
                  '이 사용자 차단',
                  style: TextStyle(color: wc.danger),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _handleBlock(BuildContext context, WidgetRef ref) async {
    if (authorMemberId == null) return;

    final confirmed = await showAdaptiveConfirmDialog(
      context,
      title: '$authorName 님 차단',
      content: '이 사용자의 기도/댓글이 더 이상 보이지 않습니다.\n'
          '설정 > 차단 관리에서 해제할 수 있습니다.',
      confirmText: '차단',
      isDestructive: true,
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(blocklistProvider.notifier)
          .block(authorMemberId!);
      if (!context.mounted) return;
      // 기도 목록/상세 캐시 갱신 — 차단한 사용자 글이 즉시 사라지도록
      ref.invalidate(prayerListProvider);
      ref.invalidate(commentsProvider(prayerId));
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$authorName 님을 차단했습니다.')),
      );
    } on DioException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('차단에 실패했습니다.')),
        );
      }
    }
  }
}

void _showErrorMessage(BuildContext context, String message) {
  if (isIOS) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
