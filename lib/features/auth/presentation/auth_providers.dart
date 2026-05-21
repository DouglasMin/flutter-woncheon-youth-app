import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woncheon_youth/features/auth/data/auth_repository.dart';
import 'package:woncheon_youth/shared/providers/providers.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(secureStorageServiceProvider),
  );
});
