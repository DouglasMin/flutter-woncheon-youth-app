import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:woncheon_youth/core/constants.dart';
import 'package:woncheon_youth/features/member/domain/blocked_member.dart';

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

  // Blocked members (UGC 차단 목록)
  Future<List<BlockedMember>> getBlockedMembers() async {
    final raw = await _storage.read(key: AppConstants.blockedMembersKey);
    if (raw == null || raw.isEmpty) return const [];
    // JSON 파싱/타입 캐스팅 전반에서 실패하면 빈 목록으로 폴백 (앱 구동 우선).
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final result = <BlockedMember>[];
      for (final e in decoded) {
        if (e is Map<String, dynamic>) {
          result.add(BlockedMember.fromJson(e));
        }
      }
      return result;
    } on Object {
      return const [];
    }
  }

  Future<void> setBlockedMembers(List<BlockedMember> members) async {
    final encoded = jsonEncode(members.map((m) => m.toJson()).toList());
    await _storage.write(
      key: AppConstants.blockedMembersKey,
      value: encoded,
    );
  }

  Future<void> clearAll() => _storage.deleteAll();
}
