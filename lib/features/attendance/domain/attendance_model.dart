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
  });

  final String memberId;
  final String memberName;
  final String? note;
  final bool isPresent;

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
        memberId: json['member_id'] as String,
        memberName: json['member_name'] as String,
        note: json['note'] as String?,
        isPresent: json['is_present'] as bool? ?? false,
      );

  GroupMember copyWith({bool? isPresent}) => GroupMember(
        memberId: memberId,
        memberName: memberName,
        note: note,
        isPresent: isPresent ?? this.isPresent,
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
