import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:woncheon_youth/features/attendance/data/attendance_repository.dart';
import 'package:woncheon_youth/features/attendance/domain/attendance_model.dart';
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

// 내 목장 주간 출석 현황
final weeklyAttendanceProvider = FutureProvider<
    ({GroupInfo group, String date, List<GroupMember> members})>((ref) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  final date = ref.watch(selectedDateProvider);
  return repo.getWeekly(date);
});

// 목장별 출석률 통계
final attendanceStatsProvider =
    FutureProvider.family<List<GroupStats>, String>((ref, period) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.getStats(period: period);
});
