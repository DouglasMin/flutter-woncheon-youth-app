import 'package:flutter_test/flutter_test.dart';
import 'package:woncheon_youth/core/router/app_router.dart';
import 'package:woncheon_youth/features/splash/presentation/splash_page.dart';

void main() {
  test(
    'startup route decision only depends on token and first-login state',
    () {
      expect(
        decideStartupRoute(hasAccessToken: false, isFirstLogin: false),
        AppRoutes.login,
      );
      expect(
        decideStartupRoute(hasAccessToken: true, isFirstLogin: true),
        AppRoutes.changePassword,
      );
      expect(
        decideStartupRoute(hasAccessToken: true, isFirstLogin: false),
        AppRoutes.home,
      );
    },
  );
}
