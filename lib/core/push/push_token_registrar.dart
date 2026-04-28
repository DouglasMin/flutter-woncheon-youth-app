import 'dart:async';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woncheon_youth/core/push/push_providers.dart';
import 'package:woncheon_youth/shared/providers/providers.dart';

/// 알림 권한을 요청하고, 발급된 디바이스 토큰을 백엔드에 등록.
/// 로그인 / 비번 변경 직후에 호출 — 재설치, 다기기, 토큰 로테이션 시에도
/// 항상 최신 토큰이 등록되도록 보장. 백엔드는 (memberId, token) 키로 dedup.
Future<void> registerDeviceTokenAfterAuth(WidgetRef ref) async {
  final pushService = ref.read(pushNotificationServiceProvider);
  final granted = await pushService.requestPermission();
  if (!granted) return;

  final platform = Platform.isIOS ? 'ios' : 'android';
  StreamSubscription<String>? sub;
  Timer? timeout;

  sub = pushService.onTokenReceived.listen((token) async {
    try {
      await ref.read(apiClientProvider).dio.post<Map<String, dynamic>>(
        '/auth/device-token',
        data: {'token': token, 'platform': platform},
      );
    } on DioException catch (e) {
      debugPrint('Failed to register device token: $e');
    } finally {
      await sub?.cancel();
      timeout?.cancel();
    }
  });
  timeout = Timer(const Duration(seconds: 10), () {
    sub?.cancel();
  });
}
