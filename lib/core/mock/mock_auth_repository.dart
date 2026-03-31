import 'package:woncheon_youth/core/storage/secure_storage.dart';

class MockAuthRepository {
  MockAuthRepository(this._storage);

  final SecureStorageService _storage;

  static const _testName = 'test';
  static const _testPassword = '1111';
  static const _testNewPassword = 'newpass123';

  bool _isFirstLogin = true;

  Future<Map<String, dynamic>> login({
    required String name,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (name != _testName) {
      throw MockApiException(401, 'MEMBER_NOT_FOUND', '등록된 청년부원이 아닙니다.');
    }

    if (password != _testPassword && password != _testNewPassword) {
      throw MockApiException(401, 'INVALID_PASSWORD', '비밀번호를 확인해주세요.');
    }

    if (password == _testNewPassword) {
      _isFirstLogin = false;
    }

    await _storage.saveTokens(
      accessToken: 'mock-access-token',
      refreshToken: 'mock-refresh-token',
    );
    await _storage.setMemberId('mock-member-001');
    await _storage.setMemberName(name);

    return {
      'accessToken': 'mock-access-token',
      'refreshToken': 'mock-refresh-token',
      'isFirstLogin': _isFirstLogin,
      'member': {
        'memberId': 'mock-member-001',
        'name': name,
      },
    };
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (currentPassword != _testPassword) {
      throw MockApiException(
        400,
        'INVALID_CURRENT_PASSWORD',
        '현재 비밀번호가 올바르지 않습니다.',
      );
    }

    if (newPassword.length < 8) {
      throw MockApiException(400, 'VALIDATION_ERROR', '8자 이상 입력해주세요.');
    }

    _isFirstLogin = false;
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.getAccessToken();
    return token != null;
  }
}

class MockApiException implements Exception {
  MockApiException(this.statusCode, this.code, this.message);

  final int statusCode;
  final String code;
  final String message;

  @override
  String toString() => message;
}
