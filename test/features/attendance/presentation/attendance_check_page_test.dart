import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:woncheon_youth/features/attendance/domain/attendance_model.dart';
import 'package:woncheon_youth/features/attendance/presentation/attendance_check_page.dart';
import 'package:woncheon_youth/features/attendance/presentation/attendance_providers.dart';
import 'package:woncheon_youth/features/prayer/domain/prayer_model.dart';

void main() {
  testWidgets('attendance core renders before group prayers finish', (
    tester,
  ) async {
    await initializeDateFormatting('ko');
    final groupPrayers = Completer<List<PrayerItem>>();
    const weekly = WeeklyAttendance(
      isLeader: false,
      group: GroupInfo(id: 1, name: '테스트'),
      date: '2026-07-12',
      today: TodayStatus(isPresent: false, hasRecord: false),
      history: [],
      stats: MyStats(totalWeeks: 12, presentWeeks: 7, rate: 58.3),
      members: [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weeklyAttendanceProvider.overrideWith((ref) async => weekly),
          groupPrayersProvider.overrideWith((ref) => groupPrayers.future),
        ],
        child: const MaterialApp(home: AttendanceCheckPage()),
      ),
    );
    await tester.pump();

    expect(find.text('테스트 목장'), findsOneWidget);
    expect(find.text('목장 기도제목'), findsOneWidget);
    expect(find.text('목장 기도제목을 불러오는 중'), findsOneWidget);
  });
}
