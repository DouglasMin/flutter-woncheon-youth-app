import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woncheon_youth/features/auth/presentation/change_password_page.dart';
import 'package:woncheon_youth/features/auth/presentation/login_page.dart';
import 'package:woncheon_youth/features/home/presentation/home_page.dart';
import 'package:woncheon_youth/features/prayer/presentation/prayer_create_page.dart';
import 'package:woncheon_youth/features/prayer/presentation/prayer_detail_page.dart';
import 'package:woncheon_youth/features/attendance/presentation/attendance_check_page.dart';
import 'package:woncheon_youth/features/attendance/presentation/attendance_stats_page.dart';
import 'package:woncheon_youth/features/prayer/presentation/prayer_list_page.dart';
import 'package:woncheon_youth/features/settings/presentation/settings_page.dart';
import 'package:woncheon_youth/features/splash/presentation/splash_page.dart';
import 'package:woncheon_youth/shared/providers/providers.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const changePassword = '/change-password';
  static const home = '/home';
  static const prayerList = '/prayers';
  static const prayerCreate = '/prayers/create';
  static String prayerDetail(String id) => '/prayers/$id';
  static const attendanceCheck = '/attendance';
  static const attendanceStats = '/attendance/stats';
  static const settings = '/settings';
}

final routerProvider = Provider<GoRouter>((ref) {
  final storage = ref.read(secureStorageServiceProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) async {
      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isChangePassword =
          state.matchedLocation == AppRoutes.changePassword;

      // Let splash handle its own navigation
      if (isSplash || isChangePassword) return null;

      final token = await storage.getAccessToken();
      final isLoggedIn = token != null;
      final isLoginRoute = state.matchedLocation == AppRoutes.login;

      if (!isLoggedIn && !isLoginRoute) return AppRoutes.login;
      if (isLoggedIn && isLoginRoute) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.prayerList,
        builder: (context, state) => const PrayerListPage(),
      ),
      GoRoute(
        path: AppRoutes.prayerCreate,
        builder: (context, state) => const PrayerCreatePage(),
      ),
      GoRoute(
        path: '/prayers/:prayerId',
        builder: (context, state) {
          final prayerId = state.pathParameters['prayerId']!;
          return PrayerDetailPage(prayerId: prayerId);
        },
      ),
      GoRoute(
        path: AppRoutes.attendanceCheck,
        builder: (context, state) => const AttendanceCheckPage(),
      ),
      GoRoute(
        path: AppRoutes.attendanceStats,
        builder: (context, state) => const AttendanceStatsPage(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
});
