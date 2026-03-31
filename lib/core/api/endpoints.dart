abstract final class Endpoints {
  // Auth
  static const String login = '/auth/login';
  static const String changePassword = '/auth/change-password';
  static const String refresh = '/auth/refresh';
  static const String deviceToken = '/auth/device-token';

  // Prayer
  static const String prayers = '/prayers';
  static String prayer(String prayerId) => '/prayers/$prayerId';
}
