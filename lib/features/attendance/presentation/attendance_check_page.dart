import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/features/attendance/domain/attendance_model.dart';
import 'package:woncheon_youth/features/attendance/presentation/attendance_providers.dart';
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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _ErrorView(
            onRetry: () => ref.invalidate(weeklyAttendanceProvider),
          ),
          data: (data) {
            if (data.isLeader) {
              return _LeaderView(data: data);
            }
            return _MemberView(data: data);
          },
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────
// Leader view — 기존 출석 체크 UI
// ───────────────────────────────────────────────────────────

class _LeaderView extends ConsumerStatefulWidget {
  const _LeaderView({required this.data});
  final WeeklyAttendance data;

  @override
  ConsumerState<_LeaderView> createState() => _LeaderViewState();
}

class _LeaderViewState extends ConsumerState<_LeaderView> {
  List<GroupMember> _members = [];
  String? _syncedDate;
  bool _isSaving = false;
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;

    // 서버 데이터를 로컬 편집 상태로 동기화 (주일/로스터 변경 시).
    ref.listen(weeklyAttendanceProvider, (_, next) {
      final fresh = next.valueOrNull;
      final roster = fresh?.members;
      if (fresh == null || roster == null) return;
      if (_syncedDate == fresh.date &&
          _members.length == roster.length) {
        return;
      }
      setState(() {
        _members = roster;
        _syncedDate = fresh.date;
        _saved = false;
      });
    });

    final roster = widget.data.members ?? const <GroupMember>[];
    final members =
        _syncedDate == widget.data.date ? _members : roster;
    final presentCount = members.where((m) => m.isPresent).length;
    final parsed = DateTime.parse(widget.data.date);
    final dateLabel = DateFormat('yyyy년 M월 d일 (E)', 'ko').format(parsed);

    return Stack(
      children: [
        Column(
          children: [
            _LeaderHeader(date: dateLabel, groupName: widget.data.group.name),
            _SummaryCard(
              present: presentCount,
              total: members.length,
              onMarkAll: () => _markAll(members),
              onClearAll: () => _clearAll(members),
            ),
            const _WeekNav(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 6),
              child: Row(
                children: [
                  Text(
                    '목원 ${members.length}명',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: wc.textSec,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '탭해서 체크',
                    style: TextStyle(fontSize: 11, color: wc.textTer),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 180),
                child: GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    mainAxisExtent: 108,
                  ),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return _MemberTile(
                      member: member,
                      onToggle: () => _toggleMember(index, member),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24 + MediaQuery.of(context).padding.bottom,
          child: _ConfirmButton(
            present: presentCount,
            total: members.length,
            saved: _saved,
            isSaving: _isSaving,
            onTap: _save,
          ),
        ),
        Positioned(
          left: 0,
          top: 8,
          child: IconButton(
            onPressed: () => context.pop(),
            icon: Icon(FluentIcons.chevron_left_24_regular, color: wc.text),
          ),
        ),
      ],
    );
  }

  void _toggleMember(int index, GroupMember member) {
    Haptic.selection();
    setState(() {
      _members = List.of(_members.isNotEmpty ? _members : widget.data.members!)
        ..[index] = member.copyWith(isPresent: !member.isPresent);
      _saved = false;
    });
  }

  void _markAll(List<GroupMember> members) {
    Haptic.selection();
    setState(() {
      _members = members.map((m) => m.copyWith(isPresent: true)).toList();
      _saved = false;
    });
  }

  void _clearAll(List<GroupMember> members) {
    Haptic.selection();
    setState(() {
      _members = members.map((m) => m.copyWith(isPresent: false)).toList();
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
      await repo.checkAttendance(
        date: date,
        records: _members
            .map((m) => (memberId: m.memberId, isPresent: m.isPresent))
            .toList(),
      );
      await Haptic.light();
      // 서버 데이터를 다시 받아 본인/목원 화면 즉시 반영
      ref.invalidate(weeklyAttendanceProvider);
      if (mounted) setState(() => _saved = true);
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장에 실패했습니다.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

// ───────────────────────────────────────────────────────────
// Member view — read-only 본인 출석 상태
// ───────────────────────────────────────────────────────────

class _MemberView extends ConsumerWidget {
  const _MemberView({required this.data});
  final WeeklyAttendance data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wc = context.wc;
    final parsed = DateTime.parse(data.date);
    final dateLabel = DateFormat('yyyy년 M월 d일 (E)', 'ko').format(parsed);
    final isSunday = parsed.weekday == DateTime.sunday;
    final todayIsoDate = DateTime.now()
            .toUtc()
            .toIso8601String()
            .substring(0, 10) ==
        data.date;

    return Stack(
      children: [
        RefreshIndicator(
          color: wc.accent,
          onRefresh: () async {
            ref.invalidate(weeklyAttendanceProvider);
            await ref.read(weeklyAttendanceProvider.future);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: wc.textTer,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '내 출석',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: wc.text,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    WCPill(child: Text('${data.group.name} 목장')),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _TodayStatusCard(
                  today: data.today,
                  isSunday: isSunday && todayIsoDate,
                ),
              ),
              _SectionHeader(text: '최근 4주'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _HistoryRow(
                  history: data.history,
                  currentDate: data.date,
                ),
              ),
              _SectionHeader(text: '이번 분기'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _StatsCard(stats: data.stats),
              ),
            ],
          ),
          ),
        ),
        Positioned(
          left: 0,
          top: 8,
          child: IconButton(
            onPressed: () => context.pop(),
            icon: Icon(FluentIcons.chevron_left_24_regular, color: wc.text),
          ),
        ),
      ],
    );
  }
}

class _TodayStatusCard extends StatelessWidget {
  const _TodayStatusCard({required this.today, required this.isSunday});
  final TodayStatus today;
  final bool isSunday;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;

    // 3-state: 평일 / 주일+출석 / 주일+미체크
    if (!isSunday) {
      return Container(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
        decoration: BoxDecoration(
          color: wc.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: wc.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '다음 주일',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: wc.textTer,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '주일 예배에서 만나요',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: wc.text,
                letterSpacing: -0.4,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '출석은 목장 리더가 예배 시간에 체크해요.\n내가 직접 누르지 않아도 돼요.',
              style: TextStyle(
                fontSize: 13,
                color: wc.textSec,
                height: 1.6,
              ),
            ),
          ],
        ),
      );
    }

    if (today.isPresent) {
      return Container(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
        decoration: BoxDecoration(
          color: wc.accentSoft,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: wc.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(FluentIcons.checkmark_24_regular,
                      size: 22, color: wc.bg),
                ),
                const SizedBox(width: 10),
                Text(
                  '출석 완료',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: wc.accentInk,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '오늘 예배 출석이\n기록되었어요',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: wc.accentInk,
                letterSpacing: -0.5,
                height: 1.35,
              ),
            ),
            if (today.markedBy != null || today.markedAt != null) ...[
              const SizedBox(height: 10),
              Text(
                _markedByLine(today),
                style: TextStyle(
                  fontSize: 13,
                  color: wc.accentInk.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // 주일 + 아직 체크 안 됨
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      decoration: BoxDecoration(
        color: wc.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: wc.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '아직 체크되지 않음',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: wc.textTer,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '리더가 곧 체크해줄 거예요',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: wc.text,
              letterSpacing: -0.4,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '이미 예배에 왔다면 목장 리더에게 알려주세요.',
            style: TextStyle(
              fontSize: 13,
              color: wc.textSec,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  String _markedByLine(TodayStatus today) {
    final parts = <String>[];
    if (today.markedBy != null) parts.add('${today.markedBy} 리더');
    if (today.markedAt != null) {
      parts.add(DateFormat('HH:mm').format(today.markedAt!.toLocal()));
    }
    return parts.isEmpty ? '' : '${parts.join(' · ')} 체크';
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.history, required this.currentDate});
  final List<HistoryEntry> history;
  final String currentDate;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    return Row(
      children: [
        for (final e in history) ...[
          Expanded(
            child: _HistoryCell(
              entry: e,
              isCurrent: DateFormat('yyyy-MM-dd').format(e.date) ==
                  currentDate,
            ),
          ),
          if (e != history.last) const SizedBox(width: 8),
        ],
      ],
    );
  }

  static DateFormat get _fmt => DateFormat('yyyy-MM-dd');
}

class _HistoryCell extends StatelessWidget {
  const _HistoryCell({required this.entry, required this.isCurrent});
  final HistoryEntry entry;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    final ok = entry.isPresent;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: isCurrent && ok ? wc.accentSoft : wc.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent ? wc.accent : wc.border,
        ),
      ),
      child: Column(
        children: [
          Text(
            '${entry.date.month}/${entry.date.day}',
            style: TextStyle(fontSize: 11, color: wc.textTer),
          ),
          const SizedBox(height: 6),
          Text(
            ok ? '✓' : '—',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: ok ? wc.accent : wc.textTer,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});
  final MyStats stats;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    final ratio = (stats.rate / 100).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: wc.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: wc.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '출석률',
                style: TextStyle(
                  fontSize: 14,
                  color: wc.textSec,
                ),
              ),
              const Spacer(),
              Text(
                stats.rate.toStringAsFixed(stats.rate % 1 == 0 ? 0 : 1),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: wc.text,
                  letterSpacing: -0.6,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                '%',
                style: TextStyle(
                  fontSize: 16,
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
          const SizedBox(height: 10),
          Text(
            '최근 ${stats.totalWeeks}주 중 ${stats.presentWeeks}주 출석',
            style: TextStyle(fontSize: 11.5, color: wc.textTer),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: wc.textSec,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────
// Shared sub-widgets (leader side)
// ───────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FluentIcons.error_circle_24_regular,
              size: 36, color: wc.textTer),
          const SizedBox(height: 12),
          Text(
            '출결 데이터를 불러올 수 없습니다.',
            style: TextStyle(fontSize: 15, color: wc.textSec),
            textAlign: TextAlign.center,
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

class _LeaderHeader extends StatelessWidget {
  const _LeaderHeader({required this.date, required this.groupName});
  final String date;
  final String groupName;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date,
            style: TextStyle(
              fontSize: 12,
              color: wc.textTer,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '목원 출석 체크',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: wc.text,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const WCPill(tone: WCPillTone.accent, child: Text('리더')),
              const SizedBox(width: 6),
              WCPill(child: Text('$groupName 목장')),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.present,
    required this.total,
    required this.onMarkAll,
    required this.onClearAll,
  });
  final int present;
  final int total;
  final VoidCallback onMarkAll;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
        decoration: BoxDecoration(
          color: wc.accentSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: wc.accent.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '오늘 출석',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: wc.accentInk,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: AppTheme.pretendard,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: wc.accentInk,
                        letterSpacing: -0.5,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      children: [
                        TextSpan(text: '$present'),
                        TextSpan(
                          text: ' / $total명',
                          style: TextStyle(
                            color: wc.accentInk.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                _SummaryActionBtn(
                    label: '전체 출석', filled: true, onTap: onMarkAll),
                const SizedBox(height: 6),
                _SummaryActionBtn(
                    label: '초기화', filled: false, onTap: onClearAll),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryActionBtn extends StatelessWidget {
  const _SummaryActionBtn({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: filled
                ? wc.accentInk.withValues(alpha: 0.4)
                : wc.accentInk.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: filled ? FontWeight.w600 : FontWeight.w500,
            color: wc.accentInk,
          ),
        ),
      ),
    );
  }
}

class _WeekNav extends ConsumerWidget {
  const _WeekNav();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wc = context.wc;
    final date = ref.watch(selectedDateProvider);
    final parsed = DateTime.parse(date);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(FluentIcons.chevron_left_24_regular,
                size: 20, color: wc.textSec),
            onPressed: () {
              final prev = parsed.subtract(const Duration(days: 7));
              ref.read(selectedDateProvider.notifier).state =
                  DateFormat('yyyy-MM-dd').format(prev);
            },
          ),
          Text(
            DateFormat('M월 d일 (E)', 'ko').format(parsed),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: wc.textSec,
            ),
          ),
          IconButton(
            icon: Icon(FluentIcons.chevron_right_24_regular,
                size: 20, color: wc.textSec),
            onPressed: () {
              final next = parsed.add(const Duration(days: 7));
              if (next.isBefore(DateTime.now().add(const Duration(days: 1)))) {
                ref.read(selectedDateProvider.notifier).state =
                    DateFormat('yyyy-MM-dd').format(next);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.onToggle});
  final GroupMember member;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    final present = member.isPresent;
    return Material(
      color: present ? wc.accentSoft : wc.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: present ? wc.accent : wc.border,
              width: 1.5,
            ),
            boxShadow: present
                ? [
                    BoxShadow(
                      color: wc.accent.withValues(alpha: 0.13),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: present ? wc.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            present ? Colors.transparent : wc.borderStrong,
                        width: 1.5,
                      ),
                    ),
                    child: present
                        ? Icon(
                            FluentIcons.checkmark_24_regular,
                            size: 18,
                            color: wc.bg,
                          )
                        : null,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: present
                          ? wc.accentInk.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      present ? '출석' : '대기',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: present ? wc.accentInk : wc.textTer,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                member.memberName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: present ? wc.accentInk : wc.text,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '목원',
                style: TextStyle(
                  fontSize: 11,
                  color: present ? wc.accentInk : wc.textTer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: (saved || isSaving) ? null : onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: saved
                    ? Border.all(color: wc.accent.withValues(alpha: 0.33))
                    : null,
                boxShadow: saved
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
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
                          : '출석 확인 · $present/$total명 제출',
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
              style: TextStyle(fontSize: 11, color: wc.textTer),
            ),
          ),
      ],
    );
  }
}
