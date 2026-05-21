import 'package:fl_chart/fl_chart.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/features/attendance/domain/attendance_model.dart';
import 'package:woncheon_youth/features/attendance/presentation/attendance_providers.dart';
import 'package:woncheon_youth/shared/widgets/wc_widgets.dart';

/// 개인 출석 통계 화면.
/// - 최근 12주 라인 차트 (본인)
/// - 본인 출석률 카드
/// - 우리 목장 평균 카드 (랭킹은 admin에서만 — 청년부 사용자에게는 비공개)
class AttendanceStatsPage extends ConsumerWidget {
  const AttendanceStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wc = context.wc;
    final weeklyAsync = ref.watch(weeklyAttendanceProvider);
    final groupStatsAsync = ref.watch(attendanceStatsProvider('quarter'));

    return Scaffold(
      backgroundColor: wc.bg,
      body: SafeArea(
        child: Column(
          children: [
            _NavBar(onBack: () => context.pop()),
            Expanded(
              child: weeklyAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Text('통계를 불러올 수 없습니다.',
                      style: TextStyle(color: wc.textSec)),
                ),
                data: (weekly) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _SectionLabel(label: '최근 12주 출석 추이'),
                        const SizedBox(height: 10),
                        _HistoryChart(history: weekly.history),
                        const SizedBox(height: 24),
                        const _SectionLabel(label: '내 출석률'),
                        const SizedBox(height: 10),
                        _MyRateCard(stats: weekly.stats),
                        const SizedBox(height: 24),
                        const _SectionLabel(label: '우리 목장 평균'),
                        const SizedBox(height: 10),
                        groupStatsAsync.when(
                          loading: () => _GroupAverageCard.loading(
                            groupName: weekly.group.name,
                          ),
                          error: (_, __) => _GroupAverageCard.unavailable(
                            groupName: weekly.group.name,
                          ),
                          data: (stats) {
                            final mine = stats.firstWhere(
                              (s) => s.groupId == weekly.group.id,
                              orElse: () => GroupStats(
                                groupId: weekly.group.id,
                                groupName: weekly.group.name,
                                presentCount: 0,
                                totalCount: 0,
                                ratePercent: 0,
                              ),
                            );
                            return _GroupAverageCard(stat: mine);
                          },
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

class _NavBar extends StatelessWidget {
  const _NavBar({required this.onBack});
  final VoidCallback onBack;

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
            onPressed: onBack,
            icon: Icon(FluentIcons.chevron_left_24_regular,
                color: wc.text, size: 24),
          ),
          Expanded(
            child: Text(
              '내 출석 통계',
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: wc.textSec,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

class _HistoryChart extends StatelessWidget {
  const _HistoryChart({required this.history});
  final List<HistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    if (history.isEmpty) {
      return WCCard(
        child: SizedBox(
          height: 200,
          child: Center(
            child: Text('데이터가 없습니다.',
                style: TextStyle(color: wc.textTer, fontSize: 13)),
          ),
        ),
      );
    }

    final spots = <FlSpot>[
      for (var i = 0; i < history.length; i++)
        FlSpot(i.toDouble(), history[i].isPresent ? 1 : 0),
    ];

    return WCCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 12, 8),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: -0.15,
              maxY: 1.15,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: wc.border, strokeWidth: 0.5),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 40,
                    getTitlesWidget: (value, _) {
                      final label = value == 1
                          ? '출석'
                          : value == 0
                              ? '결석'
                              : '';
                      if (label.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(label,
                            style: TextStyle(
                                color: wc.textTer,
                                fontSize: 10,
                                fontWeight: FontWeight.w500)),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: (history.length / 4).floorToDouble().clamp(1, 99),
                    reservedSize: 24,
                    getTitlesWidget: (value, _) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= history.length) {
                        return const SizedBox.shrink();
                      }
                      final d = history[idx].date;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          DateFormat('M/d').format(d),
                          style: TextStyle(color: wc.textTer, fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: false,
                  color: wc.accent,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, __, ___) {
                      final present = spot.y == 1;
                      return FlDotCirclePainter(
                        radius: 4.5,
                        color: present ? wc.accent : wc.surfaceAlt,
                        strokeWidth: 1.5,
                        strokeColor: present ? wc.accent : wc.border,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: wc.accent.withValues(alpha: 0.08),
                  ),
                ),
              ],
              lineTouchData: const LineTouchData(enabled: false),
            ),
          ),
        ),
      ),
    );
  }
}

class _MyRateCard extends StatelessWidget {
  const _MyRateCard({required this.stats});
  final MyStats stats;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    final ratePercent = stats.rate;
    final rateColor = ratePercent >= 80
        ? wc.success
        : ratePercent >= 50
            ? wc.accent
            : wc.danger;

    return WCCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${stats.presentWeeks}/${stats.totalWeeks}회 출석',
                    style: TextStyle(
                      fontSize: 13,
                      color: wc.textSec,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '최근 ${stats.totalWeeks}주 기준',
                    style: TextStyle(
                      fontSize: 11,
                      color: wc.textTer,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${ratePercent.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: rateColor,
                fontFeatures: const [FontFeature.tabularFigures()],
                letterSpacing: -1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupAverageCard extends StatelessWidget {
  const _GroupAverageCard({required this.stat})
      : _placeholder = null,
        _loading = false;

  const _GroupAverageCard.loading({required String groupName})
      : stat = null,
        _placeholder = groupName,
        _loading = true;

  const _GroupAverageCard.unavailable({required String groupName})
      : stat = null,
        _placeholder = groupName,
        _loading = false;

  final GroupStats? stat;
  final String? _placeholder;
  final bool _loading;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    final s = stat;
    final groupName = s?.groupName ?? _placeholder ?? '';
    final hasData = s != null && s.totalCount > 0;

    return WCCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$groupName 목장',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: wc.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasData
                        ? '${s.presentCount}/${s.totalCount}명 출석 (이번 분기)'
                        : _loading
                            ? '불러오는 중...'
                            : '데이터 없음',
                    style: TextStyle(
                      fontSize: 11,
                      color: wc.textTer,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              hasData ? '${s.ratePercent.toStringAsFixed(0)}%' : '—',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: hasData ? wc.textSec : wc.textTer,
                fontFeatures: const [FontFeature.tabularFigures()],
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
