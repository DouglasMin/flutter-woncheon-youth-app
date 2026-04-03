import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/features/attendance/domain/attendance_model.dart';
import 'package:woncheon_youth/features/attendance/presentation/attendance_providers.dart';
import 'package:woncheon_youth/shared/widgets/adaptive.dart';

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

  @override
  Widget build(BuildContext context) {
    final weeklyAsync = ref.watch(weeklyAttendanceProvider);

    final content = weeklyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FluentIcons.error_circle_24_regular,
              size: 48,
              color: AppColors.error.withAlpha(150),
            ),
            const SizedBox(height: 16),
            Text('오류: $e'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(weeklyAttendanceProvider),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
      data: (data) {
        // 서버 데이터가 바뀔 때마다 멤버 상태 갱신
        if (_members.isEmpty ||
            _members.length != data.members.length ||
            _currentDate != data.date) {
          _members = data.members;
          _currentDate = data.date;
        }

        return Column(
          children: [
            // 날짜 선택
            _DateSelector(ref: ref),
            const Divider(height: 1),
            // 출석 현황 요약
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${data.group.name} 목장',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_members.where((m) => m.isPresent).length}/${_members.length}명 출석',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // 목원 체크리스트 (2열 그리드)
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.8,
                ),
                itemCount: _members.length,
                itemBuilder: (context, index) {
                  final member = _members[index];
                  return _MemberCheckCard(
                    member: member,
                    onToggle: () {
                      Haptic.selection();
                      setState(() {
                        _members[index] =
                            member.copyWith(isPresent: !member.isPresent);
                      });
                    },
                  );
                },
              ),
            ),
            // 저장 버튼
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: AdaptiveButton(
                  onPressed: _isSaving ? null : _save,
                  isLoading: _isSaving,
                  child: Text(
                    '저장 (${_members.where((m) => m.isPresent).length}/${_members.length}명 출석)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text(
            '출석 체크',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor:
              MediaQuery.platformBrightnessOf(context) == Brightness.dark
                  ? AppTheme.cupertinoDark.barBackgroundColor
                  : AppTheme.cupertinoLight.barBackgroundColor,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(top: false, child: content),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('출석 체크')),
      body: content,
    );
  }

  Future<void> _save() async {
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
      if (mounted) {
        _showErrorMessage(context, '출석이 저장되었습니다.', isError: false);
      }
    } catch (_) {
      if (mounted) {
        _showErrorMessage(context, '저장에 실패했습니다.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showErrorMessage(
    BuildContext context,
    String message, {
    bool isError = true,
  }) {
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
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final date = ref.watch(selectedDateProvider);
    final parsed = DateTime.parse(date);
    final formatted = DateFormat('M월 d일 (E)', 'ko').format(parsed);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(FluentIcons.chevron_left_24_regular, size: 20),
            onPressed: () {
              final prev = parsed.subtract(const Duration(days: 7));
              ref.read(selectedDateProvider.notifier).state =
                  DateFormat('yyyy-MM-dd').format(prev);
            },
          ),
          Expanded(
            child: Text(
              formatted,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(FluentIcons.chevron_right_24_regular, size: 20),
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

class _MemberCheckCard extends StatelessWidget {
  const _MemberCheckCard({
    required this.member,
    required this.onToggle,
  });

  final GroupMember member;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: member.isPresent
              ? AppColors.success.withAlpha(15)
              : context.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: member.isPresent
                ? AppColors.success.withAlpha(80)
                : context.dividerColor,
            width: member.isPresent ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            // Check icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: member.isPresent
                    ? AppColors.success
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: member.isPresent
                      ? AppColors.success
                      : context.textTertiary,
                  width: 2,
                ),
              ),
              child: member.isPresent
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            // Name
            Expanded(
              child: Text(
                member.memberName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: member.isPresent ? FontWeight.w600 : FontWeight.w400,
                  color: member.isPresent
                      ? AppColors.success
                      : context.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
