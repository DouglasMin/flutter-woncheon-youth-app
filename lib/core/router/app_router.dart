import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woncheon_youth/features/attendance/presentation/attendance_check_page.dart';
import 'package:woncheon_youth/features/attendance/presentation/attendance_stats_page.dart';
import 'package:woncheon_youth/features/auth/presentation/change_password_page.dart';
import 'package:woncheon_youth/features/auth/presentation/login_page.dart';
import 'package:woncheon_youth/features/auth/presentation/register_request_page.dart';
import 'package:woncheon_youth/features/home/presentation/home_page.dart';
import 'package:woncheon_youth/features/member/presentation/blocks_page.dart';
import 'package:woncheon_youth/features/prayer/presentation/prayer_create_page.dart';
import 'package:woncheon_youth/features/prayer/presentation/prayer_detail_page.dart';
import 'package:woncheon_youth/features/prayer/presentation/prayer_list_page.dart';
import 'package:woncheon_youth/features/settings/presentation/settings_page.dart';
import 'package:woncheon_youth/features/splash/presentation/splash_page.dart';
import 'package:woncheon_youth/shared/providers/providers.dart';
import 'package:woncheon_youth/shared/widgets/tab_shell.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const changePassword = '/change-password';
  static const registerRequest = '/register';

  // Tab branches
  static const home = '/home';
  static const prayerList = '/prayers';
  static const attendanceCheck = '/attendance';
  static const settings = '/settings';

  // Stacked over tabs
  static const prayerCreate = '/prayers/create';
  static String prayerDetail(String id) => '/prayers/$id';
  static const attendanceStats = '/attendance/stats';
  static const blocks = '/settings/blocks';
}

final _rootKey = GlobalKey<NavigatorState>();
final _homeKey = GlobalKey<NavigatorState>();
final _prayerKey = GlobalKey<NavigatorState>();
final _attendanceKey = GlobalKey<NavigatorState>();
final _settingsKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final storage = ref.read(secureStorageServiceProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.splash,
    redirect: (context, state) async {
      final loc = state.matchedLocation;
      final isSplash = loc == AppRoutes.splash;
      final isChangePassword = loc == AppRoutes.changePassword;
      final isRegister = loc == AppRoutes.registerRequest;

      if (isSplash || isChangePassword || isRegister) return null;

      final token = await storage.getAccessToken();
      final isLoggedIn = token != null;
      final isLoginRoute = loc == AppRoutes.login;

      if (!isLoggedIn && !isLoginRoute) return AppRoutes.login;
      if (isLoggedIn && isLoginRoute) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.registerRequest,
        builder: (_, __) => const RegisterRequestPage(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (_, __) => const ChangePasswordPage(),
      ),
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootKey,
        builder: (context, state, shell) => TabShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeKey,
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, __) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _prayerKey,
            routes: [
              GoRoute(
                path: AppRoutes.prayerList,
                builder: (_, __) => const PrayerListPage(),
                routes: [
                  GoRoute(
                    path: 'create',
                    parentNavigatorKey: _rootKey,
                    builder: (_, __) => const PrayerCreatePage(),
                  ),
                  GoRoute(
                    path: ':prayerId',
                    parentNavigatorKey: _rootKey,
                    builder: (_, state) => PrayerDetailPage(
                      prayerId: state.pathParameters['prayerId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _attendanceKey,
            routes: [
              GoRoute(
                path: AppRoutes.attendanceCheck,
                builder: (_, __) => const AttendanceCheckPage(),
                routes: [
                  GoRoute(
                    path: 'stats',
                    parentNavigatorKey: _rootKey,
                    builder: (_, __) => const AttendanceStatsPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _settingsKey,
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (_, __) => const SettingsPage(),
                routes: [
                  GoRoute(
                    path: 'blocks',
                    parentNavigatorKey: _rootKey,
                    builder: (_, __) => const BlocksPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
