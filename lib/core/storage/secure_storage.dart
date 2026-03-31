import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:woncheon_youth/core/constants.dart';

class SecureStorageService {
  SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  // Access Token
  Future<String?> getAccessToken() =>
      _storage.read(key: AppConstants.accessTokenKey);

  Future<void> setAccessToken(String token) =>
      _storage.write(key: AppConstants.accessTokenKey, value: token);

  // Refresh Token
  Future<String?> getRefreshToken() =>
      _storage.read(key: AppConstants.refreshTokenKey);

  Future<void> setRefreshToken(String token) =>
      _storage.write(key: AppConstants.refreshTokenKey, value: token);

  // Member Info
  Future<String?> getMemberId() =>
      _storage.read(key: AppConstants.memberIdKey);

  Future<void> setMemberId(String id) =>
      _storage.write(key: AppConstants.memberIdKey, value: id);

  Future<String?> getMemberName() =>
      _storage.read(key: AppConstants.memberNameKey);

  Future<void> setMemberName(String name) =>
      _storage.write(key: AppConstants.memberNameKey, value: name);

  // Tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      setAccessToken(accessToken),
      setRefreshToken(refreshToken),
    ]);
  }

  Future<void> clearAll() => _storage.deleteAll();
}
