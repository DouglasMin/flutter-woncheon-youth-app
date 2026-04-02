import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woncheon_youth/core/api/api_error.dart';
import 'package:woncheon_youth/core/constants.dart';
import 'package:woncheon_youth/core/mock/mock_mode.dart';
import 'package:woncheon_youth/features/prayer/presentation/prayer_providers.dart';
import 'package:woncheon_youth/shared/widgets/adaptive.dart';

class PrayerCreatePage extends ConsumerStatefulWidget {
  const PrayerCreatePage({super.key});

  @override
  ConsumerState<PrayerCreatePage> createState() => _PrayerCreatePageState();
}

class _PrayerCreatePageState extends ConsumerState<PrayerCreatePage> {
  final _contentController = TextEditingController();
  bool _isAnonymous = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final content = _contentController.text.trim();

    if (content.isEmpty) {
      setState(() => _errorMessage = '내용을 입력해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Haptic.medium();

    try {
      if (kMockMode) {
        final mockRepo = ref.read(mockPrayerRepositoryProvider);
        await mockRepo.createPrayer(
          content: content,
          isAnonymous: _isAnonymous,
        );
      } else {
        final repo = ref.read(prayerRepositoryProvider);
        await repo.createPrayer(content: content, isAnonymous: _isAnonymous);
      }

      if (!mounted) return;
      unawaited(Haptic.light());
      context.pop(true);
    } on DioException catch (e) {
      await Haptic.heavy();
      setState(
        () => _errorMessage = getApiErrorMessage(e, fallback: '등록에 실패했습니다.'),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final charCount = _contentController.text.length;
    const maxLen = AppConstants.maxPrayerContentLength;

    final appBarActions = [
      if (isIOS)
        CupertinoButton(
          onPressed: _isLoading ? null : _handleSubmit,
          padding: EdgeInsets.zero,
          child: _isLoading
              ? const CupertinoActivityIndicator()
              : const Text(
                  '등록',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.activeBlue,
                  ),
                ),
        )
      else
        TextButton(
          onPressed: _isLoading ? null : _handleSubmit,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('등록', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
    ];

    final body = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: isIOS
                ? CupertinoTextField(
                    controller: _contentController,
                    maxLength: maxLen,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    placeholder: '기도 제목을 나눠주세요...',
                    decoration: const BoxDecoration(),
                    padding: const EdgeInsets.all(8),
                    style: theme.textTheme.bodyLarge,
                    onChanged: (_) => setState(() {}),
                  )
                : TextField(
                    controller: _contentController,
                    maxLength: maxLen,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      hintText: '기도 제목을 나눠주세요...',
                      border: InputBorder.none,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 14),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: theme.dividerColor.withAlpha(50)),
              ),
            ),
            child: Row(
              children: [
                if (isIOS)
                  CupertinoSwitch(
                    value: _isAnonymous,
                    onChanged: (v) {
                      Haptic.selection();
                      setState(() => _isAnonymous = v);
                    },
                  )
                else
                  Switch(
                    value: _isAnonymous,
                    onChanged: (v) {
                      Haptic.selection();
                      setState(() => _isAnonymous = v);
                    },
                  ),
                const SizedBox(width: 8),
                Text('익명으로 작성', style: theme.textTheme.bodyMedium),
                const Spacer(),
                Text(
                  '$charCount/$maxLen',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: charCount > maxLen * 0.9
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('중보기도 작성'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: appBarActions,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(child: body),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('중보기도 작성'), actions: appBarActions),
      body: body,
    );
  }
}
