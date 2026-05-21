import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:woncheon_youth/shared/widgets/adaptive.dart';

/// iOS용 강제 업데이트 다이얼로그.
/// dismiss 불가, 단일 "업데이트" 버튼만 노출. 누르면 App Store URL을 외부로 연다.
///
/// Android는 in_app_update 패키지의 IMMEDIATE flow가 시스템 UI를 띄우므로
/// 이 다이얼로그 불필요.
Future<void> showForceUpdateDialog({
  required BuildContext context,
  required String storeUrl,
  required String latestVersion,
}) async {
  await showAdaptiveDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return PopScope(
        canPop: false,
        child: isIOS
            ? _CupertinoForceUpdateDialog(
                storeUrl: storeUrl,
                latestVersion: latestVersion,
              )
            : _MaterialForceUpdateDialog(
                storeUrl: storeUrl,
                latestVersion: latestVersion,
              ),
      );
    },
  );
}

class _CupertinoForceUpdateDialog extends StatelessWidget {
  const _CupertinoForceUpdateDialog({
    required this.storeUrl,
    required this.latestVersion,
  });

  final String storeUrl;
  final String latestVersion;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('업데이트가 필요합니다'),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          '원천청년부의 새 버전($latestVersion)이 출시됐어요.\n'
          '계속 사용하려면 업데이트해주세요.',
        ),
      ),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => _openStore(storeUrl),
          child: const Text('업데이트'),
        ),
      ],
    );
  }
}

class _MaterialForceUpdateDialog extends StatelessWidget {
  const _MaterialForceUpdateDialog({
    required this.storeUrl,
    required this.latestVersion,
  });

  final String storeUrl;
  final String latestVersion;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('업데이트가 필요합니다'),
      content: Text(
        '원천청년부의 새 버전($latestVersion)이 출시됐어요.\n'
        '계속 사용하려면 업데이트해주세요.',
      ),
      actions: [
        TextButton(
          onPressed: () => _openStore(storeUrl),
          child: const Text('업데이트'),
        ),
      ],
    );
  }
}

Future<void> _openStore(String storeUrl) async {
  final uri = Uri.parse(storeUrl);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
