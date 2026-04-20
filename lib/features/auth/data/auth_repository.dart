import 'package:woncheon_youth/core/api/api_client.dart';
import 'package:woncheon_youth/core/api/endpoints.dart';
import 'package:woncheon_youth/core/storage/secure_storage.dart';
import 'package:woncheon_youth/features/member/domain/blocked_member.dart';

class AuthRepository {
  AuthRepository(this._apiClient, this._storage);

  final ApiClient _apiClient;
  final SecureStorageService _storage;

  Future<Map<String, dynamic>> login({
    required String name,
    required String password,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      Endpoints.login,
      data: {'name': name, 'password': password},
    );

    final data = response.data!['data'] as Map<String, dynamic>;

    await _storage.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );

    final member = data['member'] as Map<String, dynamic>;
    await _storage.setMemberId(member['memberId'] as String);
    await _storage.setMemberName(member['name'] as String);

    // 차단 목록 — 서버 응답이 예상 shape이 아니어도 로그인 자체는 성공해야 함
    try {
      final raw = member['blockedMembers'];
      final blocked = <BlockedMember>[];
      if (raw is List) {
        for (final e in raw) {
          if (e is Map<String, dynamic>) {
            blocked.add(BlockedMember.fromJson(e));
          }
        }
      }
      await _storage.setBlockedMembers(blocked);
    } on Object {
      // 파싱 실패해도 빈 목록으로 로그인 계속
      await _storage.setBlockedMembers(const []);
    }

    return data;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.dio.post<Map<String, dynamic>>(
      Endpoints.changePassword,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.getAccessToken();
    return token != null;
  }
}
