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

  /// Stream of device tokens when registered
  Stream<String> get onTokenReceived => _tokenController.stream;

  /// Stream of screen names when notification is tapped
  Stream<String> get onNotificationTapped => _notificationTapController.stream;

  /// Request notification permission. Returns true if granted.
  Future<bool> requestPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestPermission');
      return result ?? false;
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
    } on PlatformException catch (e) {
      debugPrint('Test notification error: $e');
      return false;
    }
  }

  /// Clear the app badge count.
  Future<void> clearBadge() async {
    try {
      await _channel.invokeMethod<void>('clearBadge');
    } on PlatformException catch (e) {
      debugPrint('Clear badge error: $e');
    }
  }

  Future<void> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'onTokenReceived':
        final token = call.arguments as String?;
        if (token != null && token.isNotEmpty) {
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
