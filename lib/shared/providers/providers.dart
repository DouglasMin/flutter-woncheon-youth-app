import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:woncheon_youth/core/api/api_client.dart';
import 'package:woncheon_youth/core/storage/secure_storage.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService(const FlutterSecureStorage());
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  return ApiClient(storage);
});
