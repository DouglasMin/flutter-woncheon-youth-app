import 'dart:async';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woncheon_youth/core/push/push_providers.dart';
import 'package:woncheon_youth/shared/providers/providers.dart';

/// 알림 권한을 요청하고, 발급된 디바이스 토큰을 백엔드에 등록.
/// 로그인 / 비번 변경 직후에 호출 — 재설치, 다기기, 토큰 로테이션 시에도
/// 항상 최신 토큰이 등록되도록 보장. 백엔드는 (memberId, token) 키로 dedup.
///
/// Android: native에서 FCM 토큰을 직접 fetch (race-free).
/// iOS: APNs는 requestPermission이 토큰 발급 트리거라 stream listen으로 받음.
Future<void> registerDeviceTokenAfterAuth(WidgetRef ref) async {
  final pushService = ref.read(pushNotificationServiceProvider);
  final granted = await pushService.requestPermission();
  if (!granted) {
    debugPrint('[push] 알림 권한 미부여 → 토큰 등록 skip');
    return;
  }

  final platform = Platform.isIOS ? 'ios' : 'android';

  // 1. 직접 fetch 시도 (Android에서 즉시 토큰 반환, iOS에선 null)
  String? token;
  try {
    token = await const MethodChannel(
      'com.woncheon.youth/push',
    ).invokeMethod<String>('getDeviceToken');
  } on PlatformException catch (e) {
    debugPrint('[push] getDeviceToken 실패: $e');
  }

  if (token != null && token.isNotEmpty) {
    await _postToken(ref, token, platform);
    return;
  }

  // 2. iOS fallback: stream으로 토큰 도착 대기 (requestPermission이 발급 트리거)
  final completer = Completer<String>();
  final sub = pushService.onTokenReceived.listen((t) {
    if (!completer.isCompleted) completer.complete(t);
  });
  try {
    final received = await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('토큰 수신 타임아웃'),
    );
    await _postToken(ref, received, platform);
  } on TimeoutException {
    debugPrint('[push] 10초 안에 토큰 수신 못함 → 등록 실패');
  } finally {
    await sub.cancel();
  }
}

Future<void> _postToken(WidgetRef ref, String token, String platform) async {
  try {
    await ref
        .read(apiClientProvider)
        .dio
        .post<Map<String, dynamic>>(
          '/auth/device-token',
          data: {'token': token, 'platform': platform},
        );
    debugPrint('[push] 토큰 등록 성공 ($platform)');
  } on DioException catch (e) {
    debugPrint('[push] 토큰 등록 실패: ${e.message}');
  }
}
