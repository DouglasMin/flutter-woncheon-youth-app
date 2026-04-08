import 'package:dio/dio.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:woncheon_youth/core/mock/mock_mode.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/features/prayer/domain/comment_model.dart';
import 'package:woncheon_youth/features/prayer/presentation/prayer_providers.dart';
import 'package:woncheon_youth/shared/providers/providers.dart';
import 'package:woncheon_youth/shared/widgets/adaptive.dart';
import 'package:woncheon_youth/shared/widgets/report_dialog.dart';

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
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: context.cardShadowColor,
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
                          style: TextStyle(
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 13,
                              color: context.textTertiary,
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
                    if (!prayer.isMine)
                      IconButton(
                        icon: Icon(
                          FluentIcons.flag_24_regular,
                          color: context.textTertiary,
                          size: 20,
                        ),
                        onPressed: () => showReportDialog(
                          context: context,
                          apiClient: ref.read(apiClientProvider),
                          targetType: 'prayer',
                          targetId: prayer.prayerId,
                        ),
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
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: context.cardShadowColor,
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  prayer.content,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.8,
                    color: context.textPrimary,
                    letterSpacing: 0.1,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Reaction button
              _ReactionButton(prayerId: prayerId),

              const SizedBox(height: 20),

              // Comments section
              _CommentsSection(prayerId: prayerId),
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
          backgroundColor: MediaQuery.platformBrightnessOf(context) == Brightness.dark
              ? AppTheme.cupertinoDark.barBackgroundColor
              : AppTheme.cupertinoLight.barBackgroundColor,
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
        _showErrorMessage(context, '삭제에 실패했습니다.');
      }
    }
  }

}

// ── Reaction Button ──
class _ReactionButton extends ConsumerWidget {
  const _ReactionButton({required this.prayerId});

  final String prayerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(reactionProvider(prayerId));
    final state = asyncState.valueOrNull ??
        const ReactionState(reacted: false, count: 0);

    return GestureDetector(
      onTap: () async {
        await Haptic.medium();
        await ref.read(reactionProvider(prayerId).notifier).toggle();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: state.reacted
              ? AppColors.accent.withAlpha(20)
              : context.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: state.reacted
                ? AppColors.accent.withAlpha(60)
                : context.dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🙏',
              style: TextStyle(fontSize: state.reacted ? 20 : 18),
            ),
            if (state.count > 0) ...[
              const SizedBox(width: 6),
              Text(
                '${state.count}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: state.reacted
                      ? AppColors.accent
                      : context.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Comments Section ──
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
    _loadMemberId();
  }

  Future<void> _loadMemberId() async {
    final storage = ref.read(secureStorageServiceProvider);
    final id = await storage.getMemberId();
    if (mounted) setState(() => _currentMemberId = id);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showCommentActions(BuildContext context, CommentItem comment) {
    Haptic.medium();
    if (isIOS) {
      showCupertinoModalPopup<void>(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                _editComment(context, comment);
              },
              child: const Text('수정'),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(ctx).pop();
                _deleteComment(context, comment);
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
                  _editComment(context, comment);
                },
              ),
              ListTile(
                leading: Icon(
                  FluentIcons.delete_24_regular,
                  color: AppColors.error,
                ),
                title: Text(
                  '삭제',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _deleteComment(context, comment);
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _editComment(
    BuildContext context,
    CommentItem comment,
  ) async {
    final editController = TextEditingController(text: comment.content);

    final newContent = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('댓글 수정'),
        content: TextField(
          controller: editController,
          maxLines: 3,
          maxLength: 200,
          decoration: const InputDecoration(
            hintText: '댓글을 수정하세요...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(editController.text),
            child: const Text('수정'),
          ),
        ],
      ),
    );

    editController.dispose();

    if (newContent == null || newContent.trim().isEmpty || !context.mounted) {
      return;
    }

    try {
      if (!kMockMode) {
        final repo = ref.read(prayerRepositoryProvider);
        await repo.updateComment(
          prayerId: widget.prayerId,
          commentId: comment.commentId,
          content: newContent.trim(),
        );
        ref.invalidate(commentsProvider(widget.prayerId));
      }
      await Haptic.light();
    } catch (_) {
      if (context.mounted) {
        _showErrorMessage(context, '댓글 수정에 실패했습니다.');
      }
    }
  }

  Future<void> _deleteComment(
    BuildContext context,
    CommentItem comment,
  ) async {
    final confirmed = await showAdaptiveConfirmDialog(
      context,
      title: '댓글 삭제',
      content: '이 댓글을 삭제하시겠습니까?',
      confirmText: '삭제',
      isDestructive: true,
    );

    if (confirmed != true || !context.mounted) return;

    try {
      if (!kMockMode) {
        final repo = ref.read(prayerRepositoryProvider);
        await repo.deleteComment(
          prayerId: widget.prayerId,
          commentId: comment.commentId,
        );
        ref.invalidate(commentsProvider(widget.prayerId));
      }
      await Haptic.light();
    } catch (_) {
      if (context.mounted) {
        _showErrorMessage(context, '댓글 삭제에 실패했습니다.');
      }
    }
  }

  Future<void> _submitComment() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);
    await Haptic.light();

    try {
      if (!kMockMode) {
        final repo = ref.read(prayerRepositoryProvider);
        await repo.createComment(
          prayerId: widget.prayerId,
          content: content,
        );
        ref.invalidate(commentsProvider(widget.prayerId));
      }
      _controller.clear();
    } catch (e) {
      debugPrint('[Comment] Error: $e');
      if (mounted) {
        _showErrorMessage(context, '댓글 작성에 실패했습니다.');
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsProvider(widget.prayerId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '댓글',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: context.textSecondary,
          ),
        ),
        const SizedBox(height: 12),

        // Comment input
        Row(
          children: [
            Expanded(
              child: AdaptiveTextField(
                controller: _controller,
                placeholder: '댓글을 입력하세요...',
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submitComment(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _isSending ? null : _submitComment,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      FluentIcons.send_24_filled,
                      color: AppColors.accent,
                    ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Comments list
        commentsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => Text(
            '댓글을 불러올 수 없습니다.',
            style: TextStyle(color: context.textTertiary, fontSize: 13),
          ),
          data: (comments) {
            if (comments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '아직 댓글이 없습니다.',
                  style: TextStyle(color: context.textTertiary, fontSize: 13),
                ),
              );
            }

            return Column(
              children: comments.map((c) {
                final date = DateTime.tryParse(c.createdAt);
                final dateStr = date != null
                    ? DateFormat('M/d HH:mm', 'ko').format(date.toLocal())
                    : '';
                final isMine = _currentMemberId != null &&
                    c.memberId == _currentMemberId;

                return GestureDetector(
                  onLongPress: isMine
                      ? () => _showCommentActions(context, c)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primaryDark,
                          child: Text(
                            c.authorName.isEmpty ? '?' : c.authorName[0],
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    c.authorName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    dateStr,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: context.textTertiary,
                                    ),
                                  ),
                                  if (isMine) ...[
                                    const Spacer(),
                                    Text(
                                      '꾹 눌러서 수정/삭제',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: context.textTertiary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                c.content,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: context.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
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
