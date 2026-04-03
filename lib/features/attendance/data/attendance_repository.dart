import 'package:woncheon_youth/core/api/api_client.dart';
import 'package:woncheon_youth/core/api/endpoints.dart';
import 'package:woncheon_youth/features/attendance/domain/attendance_model.dart';

class AttendanceRepository {
  AttendanceRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<({GroupInfo group, List<GroupMember> members})> getMyGroup() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      Endpoints.attendanceMyGroup,
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    final group = GroupInfo.fromJson(data['group'] as Map<String, dynamic>);
    final members = (data['members'] as List<dynamic>)
        .map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
        .toList();
    return (group: group, members: members);
  }

  Future<({GroupInfo group, String date, List<GroupMember> members})>
      getWeekly(String date) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      Endpoints.attendanceWeekly,
      queryParameters: {'date': date},
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    final group = GroupInfo.fromJson(data['group'] as Map<String, dynamic>);
    final members = (data['members'] as List<dynamic>)
        .map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
        .toList();
    return (group: group, date: data['date'] as String, members: members);
  }

  Future<void> checkAttendance({
    required String date,
    required List<({String memberId, bool isPresent})> records,
  }) async {
    await _apiClient.dio.post<Map<String, dynamic>>(
      Endpoints.attendanceCheck,
      data: {
        'date': date,
        'records': records
            .map((r) => {'memberId': r.memberId, 'isPresent': r.isPresent})
            .toList(),
      },
    );
  }

  Future<List<GroupStats>> getStats({String period = 'month'}) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      Endpoints.attendanceStats,
      queryParameters: {'period': period},
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return (data['groups'] as List<dynamic>)
        .map((e) => GroupStats.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
