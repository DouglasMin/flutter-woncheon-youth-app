import 'package:woncheon_youth/core/api/api_client.dart';
import 'package:woncheon_youth/core/api/endpoints.dart';
import 'package:woncheon_youth/core/storage/secure_storage.dart';

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
