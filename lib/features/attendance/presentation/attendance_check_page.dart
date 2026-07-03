import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:woncheon_youth/core/router/app_router.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/features/attendance/domain/attendance_model.dart';
import 'package:woncheon_youth/features/attendance/presentation/attendance_providers.dart';
import 'package:woncheon_youth/features/prayer/domain/prayer_model.dart';
import 'package:woncheon_youth/shared/widgets/adaptive.dart';
import 'package:woncheon_youth/shared/widgets/wc_widgets.dart';

class AttendanceCheckPage extends ConsumerWidget {
  const AttendanceCheckPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wc = context.wc;
    final weeklyAsync = ref.watch(weeklyAttendanceProvider);

    return Scaffold(
      backgroundColor: wc.bg,
      body: SafeArea(
        child: weeklyAsync.when(
          loading: () => const WCLoadingView(label: '목장 정보를 불러오는 중'),
          error: (_, __) => WCStateView(
            icon: FluentIcons.error_circle_24_regular,
            title: '목장 정보를 불러올 수 없습니다',
            message: '잠시 후 다시 시도해주세요.',
            actionLabel: '다시 시도',
            onAction: () => ref.invalidate(weeklyAttendanceProvider),
          ),
          data: (data) => _GroupPageBody(data: data),
        ),
      ),
    );
  }
}

/// 목장 페이지 본체 — 리더/멤버 공통 레이아웃.
/// - 상단: 목장 이름 + 원 아바타 + 이름 인라인 리스트
/// - 중간: 리더만 출석 체크 토글 + 제출 버튼
/// - 하단: 이 목장 멤버들의 중보기도 리스트
class _GroupPageBody extends ConsumerStatefulWidget {
  const _GroupPageBody({required this.data});
  final WeeklyAttendance data;

  @override
  ConsumerState<_GroupPageBody> createState() => _GroupPageBodyState();
}

class _GroupPageBodyState extends ConsumerState<_GroupPageBody> {
  // 리더 체크 상태 (로컬 편집)
  List<GroupMember> _editedMembers = const [];
  String? _syncedDate;
  bool _isSaving = false;
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;

    // 서버 데이터 동기화
    ref.listen(weeklyAttendanceProvider, (_, next) {
      final fresh = next.valueOrNull;
      final roster = fresh?.members;
      if (fresh == null || roster == null) return;
      if (_syncedDate == fresh.date && _editedMembers.length == roster.length) {
        return;
      }
      setState(() {
        _editedMembers = roster;
        _syncedDate = fresh.date;
        _saved = false;
      });
    });

    final data = widget.data;
    final members = data.members ?? const <GroupMember>[];
    final displayMembers = _syncedDate == data.date ? _editedMembers : members;
    final presentCount = displayMembers.where((m) => m.isPresent).length;
    final parsed = DateTime.parse(data.date);
    final dateLabel = DateFormat('yyyy년 M월 d일 (E)', 'ko').format(parsed);

    return RefreshIndicator(
      color: wc.accent,
      onRefresh: () async {
        ref
          ..invalidate(weeklyAttendanceProvider)
          ..invalidate(groupPrayersProvider);
        await ref.read(weeklyAttendanceProvider.future);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _GroupHeader(
              date: dateLabel,
              groupName: data.group.name,
              isLeader: data.isLeader,
              members: displayMembers,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                WCSpacing.pageX,
                WCSpacing.xs,
                WCSpacing.pageX,
                WCSpacing.md,
              ),
              child: _RosterStrip(
                members: displayMembers,
                showRate: data.isLeader,
                onToggle: data.isLeader ? _toggle : null,
              ),
            ),
          ),
          if (data.isLeader)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  WCSpacing.pageX,
                  0,
                  WCSpacing.pageX,
                  WCSpacing.sectionGap,
                ),
                child: _ConfirmButton(
                  present: presentCount,
                  total: displayMembers.length,
                  saved: _saved,
                  isSaving: _isSaving,
                  onTap: _save,
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  WCSpacing.pageX,
                  0,
                  WCSpacing.pageX,
                  WCSpacing.xs,
                ),
                child: _MyStatsCard(stats: data.stats),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                WCSpacing.pageX,
                WCSpacing.md,
                WCSpacing.pageX,
                WCSpacing.sm,
              ),
              child: Text(
                '목장 기도제목',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: wc.text,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
          const _GroupPrayers(),
          const SliverToBoxAdapter(
            child: SizedBox(height: WCSpacing.bottomNavClearance),
          ),
        ],
      ),
    );
  }

  void _toggle(int index) {
    final list = _syncedDate == widget.data.date
        ? _editedMembers
        : (widget.data.members ?? const <GroupMember>[]);
    if (index < 0 || index >= list.length) return;
    Haptic.selection();
    setState(() {
      _editedMembers = List.of(list)
        ..[index] = list[index].copyWith(isPresent: !list[index].isPresent);
      _syncedDate = widget.data.date;
      _saved = false;
    });
  }

  Future<void> _save() async {
    if (_isSaving || _saved) return;
    setState(() => _isSaving = true);
    await Haptic.medium();
    try {
      final repo = ref.read(attendanceRepositoryProvider);
      final date = ref.read(selectedDateProvider);
      final records = _editedMembers
          .map((m) => (memberId: m.memberId, isPresent: m.isPresent))
          .toList();
      await repo.checkAttendance(date: date, records: records);
      await Haptic.light();
      ref.invalidate(weeklyAttendanceProvider);
      if (mounted) setState(() => _saved = true);
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('저장에 실패했습니다.')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

// ───────────────────────────────────────────────────────────
// Header
// ───────────────────────────────────────────────────────────

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.date,
    required this.groupName,
    required this.isLeader,
    required this.members,
  });

  final String date;
  final String groupName;
  final bool isLeader;
  final List<GroupMember> members;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WCHeader(
            eyebrow: date,
            title: '$groupName 목장',
            trailing: IconButton(
              tooltip: '내 출석 통계',
              onPressed: () => context.push(AppRoutes.attendanceStats),
              icon: Icon(
                FluentIcons.data_pie_24_regular,
                color: wc.textSec,
                size: 22,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(
              WCSpacing.pageX,
              WCSpacing.xl,
              WCSpacing.pageX,
              WCSpacing.sm,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: WCSpacing.pageX),
            child: Row(
              children: [
                if (isLeader)
                  const Padding(
                    padding: EdgeInsets.only(right: WCSpacing.xs),
                    child: WCPill(tone: WCPillTone.accent, child: Text('리더')),
                  ),
                WCPill(child: Text('${members.length}명')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────
// Roster strip — 원 아바타 wrap
// ───────────────────────────────────────────────────────────

class _RosterStrip extends StatelessWidget {
  const _RosterStrip({
    required this.members,
    required this.showRate,
    required this.onToggle,
  });

  /// null이면 read-only (멤버 뷰)
  final void Function(int index)? onToggle;
  final List<GroupMember> members;
  final bool showRate;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    if (members.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: WCSpacing.sm),
        child: Text(
          '목장원이 등록되지 않았어요.',
          style: TextStyle(fontSize: 13, color: wc.textTer),
        ),
      );
    }
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        for (int i = 0; i < members.length; i++)
          _MemberDot(
            member: members[i],
            showRate: showRate,
            onTap: onToggle == null ? null : () => onToggle!(i),
          ),
      ],
    );
  }
}

class _MemberDot extends StatelessWidget {
  const _MemberDot({
    required this.member,
    required this.showRate,
    required this.onTap,
  });
  final GroupMember member;
  final bool showRate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    final present = member.isPresent;
    final initial = member.memberName.isEmpty
        ? '?'
        : member.memberName.characters.first;
    final rate = member.rate;

    // 출석률별 색상 (리더 전용 표시)
    final Color rateColor = rate == null
        ? wc.textTer
        : rate >= 80
        ? wc.success
        : rate >= 50
        ? wc.accent
        : wc.danger;

    return SizedBox(
      width: 60,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: present ? wc.accent : wc.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: present ? wc.accent : wc.borderStrong,
                  width: 2,
                ),
                boxShadow: present
                    ? [
                        BoxShadow(
                          color: wc.accent.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: present
                  ? Icon(
                      FluentIcons.checkmark_24_regular,
                      size: 24,
                      color: wc.bg,
                    )
                  : Text(
                      initial,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: wc.textSec,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            member.memberName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: present ? FontWeight.w700 : FontWeight.w500,
              color: present ? wc.accentInk : wc.textSec,
            ),
          ),
          if (showRate && rate != null) ...[
            const SizedBox(height: 2),
            Text(
              '${rate.toStringAsFixed(rate % 1 == 0 ? 0 : 1)}%',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: rateColor,
                fontFeatures: const [FontFeature.tabularFigures()],
                letterSpacing: -0.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────
// Member's own stats card (members only)
// ───────────────────────────────────────────────────────────

class _MyStatsCard extends StatelessWidget {
  const _MyStatsCard({required this.stats});
  final MyStats stats;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    final ratio = (stats.rate / 100).clamp(0.0, 1.0);
    return WCCard(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '내 출석률',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: wc.textSec,
                ),
              ),
              const Spacer(),
              Text(
                stats.rate.toStringAsFixed(stats.rate % 1 == 0 ? 0 : 1),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: wc.text,
                  letterSpacing: -0.6,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                '%',
                style: TextStyle(
                  fontSize: 14,
                  color: wc.textTer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(height: 6, color: wc.surfaceAlt),
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: wc.accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '최근 ${stats.totalWeeks}주 중 ${stats.presentWeeks}주 출석',
            style: TextStyle(fontSize: 11.5, color: wc.textTer),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────
// Confirm button (leader only)
// ───────────────────────────────────────────────────────────

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({
    required this.present,
    required this.total,
    required this.saved,
    required this.isSaving,
    required this.onTap,
  });

  final int present;
  final int total;
  final bool saved;
  final bool isSaving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    return Column(
      children: [
        Material(
          color: saved ? wc.accentSoft : wc.text,
          borderRadius: BorderRadius.circular(WCRadius.card),
          child: InkWell(
            onTap: (saved || isSaving) ? null : onTap,
            borderRadius: BorderRadius.circular(WCRadius.card),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(WCRadius.card),
                border: saved
                    ? Border.all(color: wc.accent.withValues(alpha: 0.33))
                    : null,
                boxShadow: saved
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSaving)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: wc.bg,
                      ),
                    )
                  else ...[
                    if (saved)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          FluentIcons.checkmark_24_regular,
                          color: wc.accentInk,
                          size: 18,
                        ),
                      ),
                    Text(
                      saved
                          ? '제출 완료 · $present/$total명'
                          : '출석 확인 · $present/$total명',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: saved ? wc.accentInk : wc.bg,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (saved)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '목원들에게 출석 결과가 전달되었어요',
              style: TextStyle(fontSize: 11, color: context.wc.textTer),
            ),
          ),
      ],
    );
  }
}

// ───────────────────────────────────────────────────────────
// Group prayers list (sliver)
// ───────────────────────────────────────────────────────────

class _GroupPrayers extends ConsumerWidget {
  const _GroupPrayers();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(groupPrayersProvider);
    return async.when(
      loading: () => const SliverToBoxAdapter(
        child: WCLoadingView(label: '목장 기도제목을 불러오는 중', compact: true),
      ),
      error: (_, __) => const SliverToBoxAdapter(
        child: WCStateView(
          icon: FluentIcons.error_circle_24_regular,
          title: '기도제목을 불러올 수 없습니다',
          compact: true,
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const SliverToBoxAdapter(
            child: WCStateView(
              icon: FluentIcons.hand_left_24_regular,
              title: '아직 올라온 기도제목이 없어요',
              message: '목장원들과 기도 제목을 나눠보세요.',
              compact: true,
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: WCSpacing.pageX),
          sliver: SliverList.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: WCSpacing.xs),
            itemBuilder: (context, i) => _GroupPrayerCard(item: items[i]),
          ),
        );
      },
    );
  }
}

class _GroupPrayerCard extends StatelessWidget {
  const _GroupPrayerCard({required this.item});
  final PrayerItem item;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    final date = DateTime.tryParse(item.createdAt);
    final dateStr = date != null ? formatRelative(date) : '';

    return WCCard(
      anon: item.isAnonymous,
      density: WCCardDensity.compact,
      onTap: () {
        Haptic.selection();
        context.push(AppRoutes.prayerDetail(item.prayerId));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (item.isAnonymous)
                const AnonPill(small: true)
              else
                Text(
                  item.authorName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.contentPreview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: item.isAnonymous ? wc.anonText : wc.textSec,
              height: 1.55,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
