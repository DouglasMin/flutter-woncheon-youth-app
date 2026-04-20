import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:woncheon_youth/features/attendance/data/attendance_repository.dart';
import 'package:woncheon_youth/features/attendance/domain/attendance_model.dart';
import 'package:woncheon_youth/features/prayer/domain/prayer_model.dart';
import 'package:woncheon_youth/features/prayer/presentation/prayer_providers.dart';
import 'package:woncheon_youth/shared/providers/providers.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(ref.watch(apiClientProvider));
});

// 선택된 날짜 (기본: 이번 주 일요일)
final selectedDateProvider = StateProvider<String>((ref) {
  final now = DateTime.now();
  final sunday = now.subtract(Duration(days: now.weekday % 7));
  return DateFormat('yyyy-MM-dd').format(sunday);
});

// 주간 출결 종합 (리더/멤버 공통)
final weeklyAttendanceProvider =
    FutureProvider<WeeklyAttendance>((ref) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  final date = ref.watch(selectedDateProvider);
  return repo.getWeekly(date);
});

/// 목장 페이지 하단에 표시할 "이 목장 멤버들이 쓴 기도".
/// weeklyAttendanceProvider에서 파생된 memberIds를 key로 서버 필터 재사용.
/// 익명 게시물도 포함 (서버가 memberId로 필터, 응답에선 authorName만 "익명"으로).
final groupPrayersProvider = FutureProvider<List<PrayerItem>>((ref) async {
  final weekly = await ref.watch(weeklyAttendanceProvider.future);
  final memberIds = <String>{
    for (final m in weekly.members ?? const <GroupMember>[])
      m.memberId,
    // 리더가 본인 목장에서 쓴 기도도 포함되도록 leader도 추가
    // (leader_member_id는 group_members에 보통 있지만, 안전장치)
  }.toList();

  if (memberIds.isEmpty) return const [];

  final repo = ref.watch(prayerRepositoryProvider);
  final response = await repo.listPrayers(
    limit: 30,
    memberIds: memberIds,
  );
  return response.items;
});

// 목장별 출석률 통계
final attendanceStatsProvider =
    FutureProvider.family<List<GroupStats>, String>((ref, period) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.getStats(period: period);
});
