import 'package:woncheon_youth/core/api/api_client.dart';
import 'package:woncheon_youth/core/api/endpoints.dart';
import 'package:woncheon_youth/features/member/domain/blocked_member.dart';

class BlockRepository {
  BlockRepository(this._apiClient);

  final ApiClient _apiClient;

  /// 사용자 차단. 서버가 업데이트된 전체 목록을 반환.
  Future<List<BlockedMember>> block(String targetMemberId) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      Endpoints.myBlocks,
      data: {'memberId': targetMemberId},
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    final items = data['blockedMembers'] as List<dynamic>;
    return items
        .map((e) => BlockedMember.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 차단 해제.
  Future<List<BlockedMember>> unblock(String targetMemberId) async {
    final response = await _apiClient.dio.delete<Map<String, dynamic>>(
      Endpoints.unblock(targetMemberId),
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    final items = data['blockedMembers'] as List<dynamic>;
    return items
        .map((e) => BlockedMember.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
