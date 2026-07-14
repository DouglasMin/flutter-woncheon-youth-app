import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:woncheon_youth/core/update/app_update_service.dart';

typedef UpdateContextProvider = BuildContext? Function();
typedef UpdateCheck = Future<void> Function(BuildContext context);

class AppUpdateLifecycleObserver with WidgetsBindingObserver {
  AppUpdateLifecycleObserver({
    required this.contextProvider,
    this.checkUpdate = AppUpdateService.ensureUpToDate,
    WidgetsBinding? binding,
  }) : _binding = binding ?? WidgetsBinding.instance;

  final UpdateContextProvider contextProvider;
  final UpdateCheck checkUpdate;
  final WidgetsBinding _binding;

  bool _checking = false;

  void start() {
    _binding.addObserver(this);
  }

  void stop() {
    _binding.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(checkNow());
    }
  }

  Future<void> checkNow() async {
    if (_checking) return;

    final context = contextProvider();
    if (context == null || !context.mounted) return;

    _checking = true;
    try {
      await checkUpdate(context);
    } finally {
      _checking = false;
    }
  }
}
