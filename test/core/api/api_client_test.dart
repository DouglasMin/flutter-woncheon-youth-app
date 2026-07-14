import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woncheon_youth/core/api/api_client.dart';
import 'package:woncheon_youth/core/storage/secure_storage.dart';

void main() {
  test(
    'ApiClient does not read secure storage for every request when token is cached',
    () async {
      final storage = _CountingSecureStorageService(accessToken: 'ACCESS');
      final client = ApiClient.forTest(storage);

      final first = await client.authorizationHeaderForTest();
      final second = await client.authorizationHeaderForTest();

      expect(first, 'Bearer ACCESS');
      expect(second, 'Bearer ACCESS');
      expect(storage.accessTokenReads, 1);
    },
  );
}

class _CountingSecureStorageService extends SecureStorageService {
  _CountingSecureStorageService({required this.accessToken})
    : super(const FlutterSecureStorage());

  final String? accessToken;
  int accessTokenReads = 0;

  @override
  Future<String?> getAccessToken() async {
    accessTokenReads += 1;
    return accessToken;
  }
}
