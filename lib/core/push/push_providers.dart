import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woncheon_youth/core/push/push_notification_service.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  final service = PushNotificationService();
  ref.onDispose(service.dispose);
  return service;
});
