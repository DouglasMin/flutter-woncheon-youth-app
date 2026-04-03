import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/features/attendance/presentation/attendance_providers.dart';
import 'package:woncheon_youth/shared/widgets/adaptive.dart';

class AttendanceStatsPage extends ConsumerStatefulWidget {
  const AttendanceStatsPage({super.key});

  @override
  ConsumerState<AttendanceStatsPage> createState() =>
      _AttendanceStatsPageState();
}

class _AttendanceStatsPageState extends ConsumerState<AttendanceStatsPage> {
  String _period = 'month';

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(attendanceStatsProvider(_period));

    final content = Column(
      children: [
        // Period selector
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _PeriodChip(
                label: '1주',
                selected: _period == 'week',
                onTap: () => setState(() => _period = 'week'),
              ),
              const SizedBox(width: 8),
              _PeriodChip(
                label: '1개월',
                selected: _period == 'month',
                onTap: () => setState(() => _period = 'month'),
              ),
              const SizedBox(width: 8),
              _PeriodChip(
                label: '3개월',
                selected: _period == 'quarter',
                onTap: () => setState(() => _period = 'quarter'),
              ),
            ],
          ),
        ),
        // Stats list
        Expanded(
          child: statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('통계를 불러올 수 없습니다.')),
            data: (stats) {
              if (stats.isEmpty) {
                return const Center(child: Text('데이터가 없습니다.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: stats.length,
                itemBuilder: (context, index) {
                  final stat = stats[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
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
                        // Rank
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: index < 3
                                ? AppColors.accent.withAlpha(20)
                                : context.dividerColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: index < 3
                                    ? AppColors.accent
                                    : context.textTertiary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Group name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${stat.groupName} 목장',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: context.textPrimary,
                                ),
                              ),
                              Text(
                                '${stat.presentCount}/${stat.totalCount}회 출석',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Rate
                        Text(
                          '${stat.ratePercent}%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: stat.ratePercent >= 80
                                ? AppColors.success
                                : stat.ratePercent >= 50
                                    ? AppColors.accent
                                    : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text(
            '목장별 출석률',
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
      appBar: AppBar(title: const Text('목장별 출석률')),
      body: content,
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Haptic.selection();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDark : context.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryDark : context.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? Colors.white : context.textSecondary,
          ),
        ),
      ),
    );
  }
}
