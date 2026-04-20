import 'package:flutter/foundation.dart';

@immutable
class BlockedMember {
  const BlockedMember({required this.memberId, required this.memberName});

  final String memberId;
  final String memberName;

  factory BlockedMember.fromJson(Map<String, dynamic> json) => BlockedMember(
        memberId: json['memberId']?.toString() ?? '',
        memberName: json['memberName']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'memberName': memberName,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BlockedMember && other.memberId == memberId);

  @override
  int get hashCode => memberId.hashCode;
}
