class GroupInfo {
  const GroupInfo({required this.id, required this.name});

  final int id;
  final String name;

  factory GroupInfo.fromJson(Map<String, dynamic> json) => GroupInfo(
        id: int.parse(json['id'].toString()),
        name: json['name'] as String,
      );
}

class GroupMember {
  const GroupMember({
    required this.memberId,
    required this.memberName,
    this.note,
    this.isPresent = false,
    this.rate,
    this.presentWeeks,
    this.totalWeeks,
  });

  final String memberId;
  final String memberName;
  final String? note;
  final bool isPresent;

  /// 최근 12주 출석률 (0~100). 리더 응답에서만 채워짐.
  final double? rate;
  final int? presentWeeks;
  final int? totalWeeks;

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
        memberId: json['member_id']?.toString() ?? '',
        memberName: json['member_name']?.toString() ?? '',
        note: json['note']?.toString(),
        isPresent: json['is_present'] == true,
        rate: (json['rate'] as num?)?.toDouble(),
        presentWeeks: (json['present_weeks'] as num?)?.toInt(),
        totalWeeks: (json['total_weeks'] as num?)?.toInt(),
      );

  GroupMember copyWith({bool? isPresent}) => GroupMember(
        memberId: memberId,
        memberName: memberName,
        note: note,
        isPresent: isPresent ?? this.isPresent,
        rate: rate,
        presentWeeks: presentWeeks,
        totalWeeks: totalWeeks,
      );
}

class GroupStats {
  const GroupStats({
    required this.groupId,
    required this.groupName,
    required this.presentCount,
    required this.totalCount,
    required this.ratePercent,
  });

  final int groupId;
  final String groupName;
  final int presentCount;
  final int totalCount;
  final double ratePercent;

  factory GroupStats.fromJson(Map<String, dynamic> json) => GroupStats(
        groupId: int.parse(json['group_id'].toString()),
        groupName: json['group_name'] as String,
        presentCount: int.parse(json['present_count']?.toString() ?? '0'),
        totalCount: int.parse(json['total_count']?.toString() ?? '0'),
        ratePercent: double.parse(json['rate_percent']?.toString() ?? '0'),
      );
}

/// 본인의 주일 출결 상태.
class TodayStatus {
  const TodayStatus({
    required this.isPresent,
    required this.hasRecord,
    this.markedBy,
    this.markedAt,
  });

  final bool isPresent;

  /// 리더가 이 주차를 열어서 출결을 기록한 적이 있는지 (false면 아직 체크 전).
  final bool hasRecord;
  final String? markedBy;
  final DateTime? markedAt;

  factory TodayStatus.fromJson(Map<String, dynamic> json) => TodayStatus(
        isPresent: json['isPresent'] == true,
        hasRecord: json['hasRecord'] == true,
        markedBy: json['markedBy'] as String?,
        markedAt: json['markedAt'] != null
            ? DateTime.tryParse(json['markedAt'] as String)
            : null,
      );
}

class HistoryEntry {
  const HistoryEntry({required this.date, required this.isPresent});
  final DateTime date;
  final bool isPresent;

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        date: DateTime.parse(json['date'] as String),
        isPresent: json['isPresent'] == true,
      );
}

class MyStats {
  const MyStats({
    required this.totalWeeks,
    required this.presentWeeks,
    required this.rate,
  });

  final int totalWeeks;
  final int presentWeeks;
  final double rate;

  factory MyStats.fromJson(Map<String, dynamic> json) => MyStats(
        totalWeeks: (json['totalWeeks'] as num).toInt(),
        presentWeeks: (json['presentWeeks'] as num).toInt(),
        rate: (json['rate'] as num).toDouble(),
      );
}

/// 주간 출결 종합 — 리더/멤버 공통 응답.
class WeeklyAttendance {
  const WeeklyAttendance({
    required this.isLeader,
    required this.group,
    required this.date,
    required this.today,
    required this.history,
    required this.stats,
    this.members,
  });

  final bool isLeader;
  final GroupInfo group;
  final String date;
  final TodayStatus today;
  final List<HistoryEntry> history;
  final MyStats stats;

  /// 리더일 때만 채워짐.
  final List<GroupMember>? members;

  factory WeeklyAttendance.fromJson(Map<String, dynamic> json) =>
      WeeklyAttendance(
        isLeader: json['isLeader'] == true,
        group: GroupInfo.fromJson(json['group'] as Map<String, dynamic>),
        date: json['date'] as String,
        today: TodayStatus.fromJson(json['today'] as Map<String, dynamic>),
        history: (json['history'] as List<dynamic>)
            .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        stats: MyStats.fromJson(json['stats'] as Map<String, dynamic>),
        members: json['members'] == null
            ? null
            : (json['members'] as List<dynamic>)
                .map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
                .toList(),
      );
}
