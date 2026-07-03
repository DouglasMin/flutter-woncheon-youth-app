abstract final class AppConstants {
  static const String appName = '원천청년부';

  // API — 단일 백엔드 운영 (Lambda stage = dev, dev/prod 인프라 분리 안 함).
  // 환경 분리는 git 브랜치(main=prod 빌드, dev=작업)로 처리.
  static const String apiBaseUrl =
      'https://ul7b1ft3di.execute-api.ap-northeast-2.amazonaws.com/dev';

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String memberIdKey = 'member_id';
  static const String memberNameKey = 'member_name';
  static const String blockedMembersKey = 'blocked_members';

  /// 초기 비번 그대로면 true. 비번 변경 성공 시 false로 set.
  /// 앱 재실행 시 splash가 이 값을 보고 changePassword 페이지로 강제 redirect.
  static const String isFirstLoginKey = 'is_first_login';

  // Pagination
  static const int defaultPageSize = 10;

  // Prayer
  static const int maxPrayerContentLength = 500;
  static const int contentPreviewLength = 200;
}
