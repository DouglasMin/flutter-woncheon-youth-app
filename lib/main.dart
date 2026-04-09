import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:woncheon_youth/core/api/auth_event_bus.dart';
import 'package:woncheon_youth/core/storage/read_prayers_storage.dart';
import 'package:woncheon_youth/core/push/push_providers.dart';
import 'package:woncheon_youth/core/router/app_router.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/l10n/app_localizations.dart' show L10n;

/// On iOS, keychain data survives app uninstall.
/// This clears it on first launch after reinstall.
Future<void> _clearKeychainOnReinstall() async {
  final prefs = await SharedPreferences.getInstance();
  final isFirstRun = prefs.getBool('first_run') ?? true;
  if (isFirstRun) {
    const storage = FlutterSecureStorage();
    await storage.deleteAll();
    await prefs.setBool('first_run', false);
  }
}

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await _clearKeychainOnReinstall();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('Unhandled platform error: $error\n$stack');
      return true;
    };

    runApp(const AppRoot());
  }, (error, stack) {
    debugPrint('Unhandled zone error: $error\n$stack');
  });
}

/// Root widget that rebuilds ProviderScope on logout to clear all cached state.
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  int _sessionKey = 0;
  StreamSubscription<AuthEvent>? _logoutSub;

  @override
  void initState() {
    super.initState();
    _logoutSub = AuthEventBus.instance.stream.listen((event) async {
      if (event == AuthEvent.logout || event == AuthEvent.forceLogout) {
        // Clear read prayer cache on logout
        await ReadPrayersStorage().clearAll();
        setState(() => _sessionKey++);
      }
    });
  }

  @override
  void dispose() {
    _logoutSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      key: ValueKey(_sessionKey),
      child: const WoncheonYouthApp(),
    );
  }
}

class WoncheonYouthApp extends ConsumerStatefulWidget {
  const WoncheonYouthApp({super.key});

  @override
  ConsumerState<WoncheonYouthApp> createState() => _WoncheonYouthAppState();
}

class _WoncheonYouthAppState extends ConsumerState<WoncheonYouthApp> {
  StreamSubscription<AuthEvent>? _authSub;
  StreamSubscription<String>? _notifTapSub;

  @override
  void initState() {
    super.initState();

    // Auth event listener
    _authSub = AuthEventBus.instance.stream.listen((event) {
      if (event == AuthEvent.forceLogout) {
        ref.read(routerProvider).go(AppRoutes.login);
      }
    });

    // Request notification permission on app start
    final pushService = ref.read(pushNotificationServiceProvider);
    pushService.requestPermission();

    // Notification tap deep link listener
    _notifTapSub = pushService.onNotificationTapped.listen((screen) {
      if (screen == 'prayer_list') {
        ref.read(routerProvider).go(AppRoutes.prayerList);
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _notifTapSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: '원천청년부',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      locale: const Locale('ko'),
    );
  }
}
