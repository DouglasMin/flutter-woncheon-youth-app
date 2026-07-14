import 'dart:convert';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:woncheon_youth/core/update/update_dialog.dart';
import 'package:woncheon_youth/core/update/version_compare.dart';

/// 앱 시작 시 1회 호출하는 강제 업데이트 체크 서비스.
///
/// - **Android**: 공식 In-App Updates (Play Core, IMMEDIATE 모드).
///   Play Store에서 설치된 경우에만 동작. APK 직접 설치 등에서는
///   `checkForUpdate()` 실패하지만 silent fail.
/// - **iOS**: iTunes Lookup API로 store 최신 버전 조회 후 SemVer 비교.
///   다르면 강제 다이얼로그(skip 없음) → "업데이트" 누르면
///   `trackViewUrl`(Apple 제공 canonical URL)로 외부 브라우저 이동.
abstract final class AppUpdateService {
  /// 개발 시 다이얼로그 UI 강제 표시.
  /// `flutter run --dart-define=FORCE_UPDATE=true`
  static const _forceForTest = bool.fromEnvironment('FORCE_UPDATE');

  static const _bundleId = 'com.woncheon.woncheonYouth';

  /// iTunes Lookup의 country 파라미터. 미지정 시 Apple 기본값은 US이고,
  /// US store는 KR store보다 새 버전 반영이 느려서 한국 사용자에게
  /// 업데이트 감지가 한 박자 늦게(또는 영영) 동작하는 버그가 있었다.
  /// 청년부는 100% 한국 App Store 사용자라 kr 고정.
  /// (공식 문서: country 미지정 시 "The default is US.")
  static const _storeCountry = 'kr';

  /// 앱 시작 시 호출. 업데이트 필요하면 차단형 다이얼로그 또는 IMMEDIATE flow.
  /// 네트워크 실패 등 어떤 오류도 사용자 흐름을 막지 않는다 (silent fail).
  static Future<void> ensureUpToDate(BuildContext context) async {
    try {
      if (_forceForTest) {
        await _showIosDialogIfMounted(
          context,
          latestVersion: '99.0.0',
          storeUrl: 'https://apps.apple.com/app/id0',
        );
        return;
      }

      if (Platform.isAndroid) {
        await _checkAndroid();
      } else if (Platform.isIOS) {
        await _checkIos(context);
      }
    } on Object catch (e, st) {
      debugPrint('[update] check failed: $e\n$st');
    }
  }

  // --------------------------------------------------------------- Android

  static Future<void> _checkAndroid() async {
    final info = await InAppUpdate.checkForUpdate();
    final available =
        info.updateAvailability == UpdateAvailability.updateAvailable;
    if (!available || !info.immediateUpdateAllowed) return;

    // IMMEDIATE: Play Store가 전체 화면 UI로 다운로드/설치/재시작까지 처리.
    await InAppUpdate.performImmediateUpdate();
  }

  // ------------------------------------------------------------------- iOS

  static Future<void> _checkIos(BuildContext context) async {
    final lookup = await _fetchIosStoreLookup();
    if (lookup == null) return;

    final localVersion = (await PackageInfo.fromPlatform()).version;
    if (!isUpdateAvailable(
      localVersion: localVersion,
      remoteVersion: lookup.version,
    )) {
      return;
    }

    if (!context.mounted) return;
    await _showIosDialogIfMounted(
      context,
      latestVersion: lookup.version,
      storeUrl: lookup.trackViewUrl,
    );
  }

  /// iTunes Lookup API — 공개, 인증 불필요.
  /// 새 버전 출시 후 store 캐시 propagation 24h~며칠 지연 가능.
  static Future<_IosLookupResult?> _fetchIosStoreLookup() async {
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      final res = await dio.get<dynamic>(
        'https://itunes.apple.com/lookup',
        queryParameters: {'bundleId': _bundleId, 'country': _storeCountry},
      );
      final data = res.data is String
          ? jsonDecode(res.data as String) as Map<String, dynamic>
          : (res.data as Map).cast<String, dynamic>();
      final results = (data['results'] as List?) ?? const [];
      if (results.isEmpty) return null;
      final first = (results.first as Map).cast<String, dynamic>();
      final version = first['version'];
      final trackViewUrl = first['trackViewUrl'];
      if (version is! String || trackViewUrl is! String) return null;
      return _IosLookupResult(version: version, trackViewUrl: trackViewUrl);
    } on Object {
      return null;
    }
  }

  static Future<void> _showIosDialogIfMounted(
    BuildContext context, {
    required String latestVersion,
    required String storeUrl,
  }) async {
    if (!context.mounted) return;
    await showForceUpdateDialog(
      context: context,
      storeUrl: storeUrl,
      latestVersion: latestVersion,
    );
  }
}

class _IosLookupResult {
  const _IosLookupResult({required this.version, required this.trackViewUrl});
  final String version;
  final String trackViewUrl;
}
