import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:woncheon_youth/core/api/api_client.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/shared/widgets/adaptive.dart';

Future<void> showReportDialog({
  required BuildContext context,
  required ApiClient apiClient,
  required String targetType, // 'prayer' or 'comment'
  required String targetId,
}) async {
  final reasons = [
    '부적절한 내용',
    '스팸/광고',
    '혐오 발언',
    '개인정보 노출',
    '기타',
  ];

  String? selectedReason;

  if (isIOS) {
    selectedReason = await showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('신고 사유를 선택해주세요'),
        actions: reasons
            .map(
              (r) => CupertinoActionSheetAction(
                onPressed: () => Navigator.of(ctx).pop(r),
                child: Text(r),
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('취소'),
        ),
      ),
    );
  } else {
    selectedReason = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '신고 사유를 선택해주세요',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            ...reasons.map(
              (r) => ListTile(
                title: Text(r),
                onTap: () => Navigator.of(ctx).pop(r),
              ),
            ),
          ],
        ),
      ),
    );
  }

  if (selectedReason == null || !context.mounted) return;

  try {
    await apiClient.dio.post<Map<String, dynamic>>(
      '/report',
      data: {
        'targetType': targetType,
        'targetId': targetId,
        'reason': selectedReason,
      },
    );

    if (context.mounted) {
      if (isIOS) {
        showCupertinoDialog<void>(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            content: const Text('신고가 접수되었습니다.'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('신고가 접수되었습니다.')),
        );
      }
    }
  } on DioException {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('신고에 실패했습니다.')),
      );
    }
  }
}
