abstract final class AppConstants {
  static const String appName = '원천청년부';

  // API
  static const String apiBaseUrlDev =
      'https://ul7b1ft3di.execute-api.ap-northeast-2.amazonaws.com/dev';
  static const String apiBaseUrlProd =
      'https://PLACEHOLDER.execute-api.ap-northeast-2.amazonaws.com/prod';

  static String get apiBaseUrl {
    const env = String.fromEnvironment('ENV', defaultValue: 'dev');
    return env == 'prod' ? apiBaseUrlProd : apiBaseUrlDev;
  }

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String memberIdKey = 'member_id';
  static const String memberNameKey = 'member_name';

  // Pagination
  static const int defaultPageSize = 20;

  // Prayer
  static const int maxPrayerContentLength = 500;
  static const int contentPreviewLength = 100;
}
