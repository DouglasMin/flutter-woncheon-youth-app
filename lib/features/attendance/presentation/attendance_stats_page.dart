import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/features/attendance/presentation/attendance_providers.dart';
import 'package:woncheon_youth/shared/widgets/wc_widgets.dart';

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
    final wc = context.wc;
    final statsAsync = ref.watch(attendanceStatsProvider(_period));

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
                      '목장별 출석률',
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  for (final (id, label) in const [
                    ('week', '1주'),
                    ('month', '1개월'),
                    ('quarter', '3개월'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: WCFilterChip(
                        label: label,
                        active: _period == id,
                        onTap: () => setState(() => _period = id),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: statsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Text('통계를 불러올 수 없습니다.',
                      style: TextStyle(color: wc.textSec)),
                ),
                data: (stats) {
                  if (stats.isEmpty) {
                    return Center(
                      child: Text('데이터가 없습니다.',
                          style: TextStyle(color: wc.textTer)),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    itemCount: stats.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final stat = stats[index];
                      final isTop = index < 3;
                      final rate = stat.ratePercent;
                      final rateColor = rate >= 80
                          ? wc.success
                          : rate >= 50
                              ? wc.accent
                              : wc.danger;
                      return WCCard(
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isTop ? wc.accentSoft : wc.surfaceAlt,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      isTop ? wc.accentInk : wc.textTer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${stat.groupName} 목장',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: wc.text,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${stat.presentCount}/${stat.totalCount}명 출석',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: wc.textTer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${rate.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: rateColor,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
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
        ),
      ),
    );
  }
}
