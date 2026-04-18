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

class AttendanceCheckPage extends ConsumerStatefulWidget {
  const AttendanceCheckPage({super.key});

  @override
  ConsumerState<AttendanceCheckPage> createState() =>
      _AttendanceCheckPageState();
}

class _AttendanceCheckPageState extends ConsumerState<AttendanceCheckPage> {
  List<GroupMember> _members = [];
  String? _currentDate;
  bool _isSaving = false;
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;

    // Sync local member state with server data via ref.listen — never mutate
    // in build(). Whenever the date or roster size changes, reset local edits.
    ref.listen(weeklyAttendanceProvider, (_, next) {
      final data = next.valueOrNull;
      if (data == null) return;
      if (_currentDate == data.date &&
          _members.length == data.members.length) {
        return;
      }
      setState(() {
        _members = data.members;
        _currentDate = data.date;
        _saved = false;
      });
    });

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
            // First-frame fallback — if the listen above hasn't run yet.
            final members = _currentDate == data.date ? _members : data.members;
            final presentCount =
                members.where((m) => m.isPresent).length;
            final parsed = DateTime.parse(data.date);
            final dateLabel =
                DateFormat('yyyy년 M월 d일 (E)', 'ko').format(parsed);

            return Stack(
              children: [
                Column(
                  children: [
                    _Header(date: dateLabel, groupName: data.group.name),
                    _SummaryCard(
                      present: presentCount,
                      total: members.length,
                      onMarkAll: _markAll,
                      onClearAll: _clearAll,
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
                            style:
                                TextStyle(fontSize: 11, color: wc.textTer),
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
                    icon: Icon(
                      FluentIcons.chevron_left_24_regular,
                      color: wc.text,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _toggleMember(int index, GroupMember member) {
    Haptic.selection();
    setState(() {
      _members = List.of(_members)
        ..[index] = member.copyWith(isPresent: !member.isPresent);
      _saved = false;
    });
  }

  void _markAll() {
    Haptic.selection();
    setState(() {
      _members =
          _members.map((m) => m.copyWith(isPresent: true)).toList();
      _saved = false;
    });
  }

  void _clearAll() {
    Haptic.selection();
    setState(() {
      _members =
          _members.map((m) => m.copyWith(isPresent: false)).toList();
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

class _Header extends StatelessWidget {
  const _Header({required this.date, required this.groupName});
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
                  label: '전체 출석',
                  filled: true,
                  onTap: onMarkAll,
                ),
                const SizedBox(height: 6),
                _SummaryActionBtn(
                  label: '초기화',
                  filled: false,
                  onTap: onClearAll,
                ),
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
