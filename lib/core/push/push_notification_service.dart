import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PushNotificationService {
  PushNotificationService() {
    _channel.setMethodCallHandler(_handleMethod);
  }

  static const _channel = MethodChannel('com.woncheon.youth/push');

  final _tokenController = StreamController<String>.broadcast();
  final _notificationTapController = StreamController<String>.broadcast();

  /// Latest received token. Cached so late subscribers can read it.
  /// Android FCM은 앱 시작 시 토큰을 자동 발급해서 listener가 붙기 전에
  /// onTokenReceived 이벤트가 dropped 될 수 있음. 캐시로 보완.
  String? _cachedToken;
  String? get cachedToken => _cachedToken;

  /// Stream of device tokens. Late subscribers automatically receive the
  /// last cached token (if any) on subscribe.
  Stream<String> get onTokenReceived async* {
    final cached = _cachedToken;
    if (cached != null) yield cached;
    yield* _tokenController.stream;
  }

  /// Stream of screen names when notification is tapped
  Stream<String> get onNotificationTapped => _notificationTapController.stream;

  /// Request notification permission. Returns true if granted.
  Future<bool> requestPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestPermission');
      return result ?? false;
    } on MissingPluginException catch (e) {
      // Android 쪽 네이티브 구현이 없을 때 등 (FCM 미구현 상태).
      // APNs Key + SNS 연동이 끝나기 전까지는 예상된 상황이므로 silent.
      debugPrint('Push channel not available on this platform: $e');
      return false;
    } on PlatformException catch (e) {
      debugPrint('Push permission error: $e');
      return false;
    }
  }

  /// Send a test local notification (fires after 2 seconds).
  Future<bool> sendTestNotification() async {
    try {
      final result = await _channel.invokeMethod<bool>('testNotification');
      return result ?? false;
    } on MissingPluginException catch (e) {
      // Android 쪽 네이티브 구현이 없을 때 등 (FCM 미구현 상태).
      // APNs Key + SNS 연동이 끝나기 전까지는 예상된 상황이므로 silent.
      debugPrint('Push channel not available on this platform: $e');
      return false;
    } on PlatformException catch (e) {
      debugPrint('Test notification error: $e');
      return false;
    }
  }

  /// Clear the app badge count.
  Future<void> clearBadge() async {
    try {
      await _channel.invokeMethod<void>('clearBadge');
    } on MissingPluginException catch (e) {
      debugPrint('Push channel not available on this platform: $e');
    } on PlatformException catch (e) {
      debugPrint('Clear badge error: $e');
    }
  }

  Future<void> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'onTokenReceived':
        final token = call.arguments as String?;
        if (token != null && token.isNotEmpty) {
          _cachedToken = token;
          _tokenController.add(token);
        }
      case 'onNotificationTapped':
        final screen = call.arguments as String?;
        if (screen != null && screen.isNotEmpty) {
          _notificationTapController.add(screen);
        }
    }
  }

  void dispose() {
    _tokenController.close();
    _notificationTapController.close();
  }
}
