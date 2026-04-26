import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woncheon_youth/core/api/api_error.dart';
import 'package:woncheon_youth/core/constants.dart';
import 'package:woncheon_youth/core/mock/mock_mode.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/features/prayer/presentation/prayer_providers.dart';
import 'package:woncheon_youth/shared/widgets/adaptive.dart';

class PrayerCreatePage extends ConsumerStatefulWidget {
  const PrayerCreatePage({super.key});

  @override
  ConsumerState<PrayerCreatePage> createState() => _PrayerCreatePageState();
}

class _PrayerCreatePageState extends ConsumerState<PrayerCreatePage> {
  final _contentController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isAnonymous = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(() => setState(() {}));
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _contentController.dispose();
    _focusNode.dispose();
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
        await ref.read(mockPrayerRepositoryProvider).createPrayer(
              content: content,
              isAnonymous: _isAnonymous,
            );
      } else {
        await ref.read(prayerRepositoryProvider).createPrayer(
              content: content,
              isAnonymous: _isAnonymous,
            );
      }
      if (!mounted) return;
      unawaited(Haptic.light());
      context.pop(true);
    } on DioException catch (e) {
      await Haptic.heavy();
      setState(() =>
          _errorMessage = getApiErrorMessage(e, fallback: '등록에 실패했습니다.'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    final charCount = _contentController.text.length;
    const maxLen = AppConstants.maxPrayerContentLength;
    final overLimit = charCount > maxLen * 0.9;
    final hasText = _contentController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: _isAnonymous ? wc.anon : wc.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Nav bar
            Container(
              padding: const EdgeInsets.fromLTRB(8, 6, 12, 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: wc.border, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => context.pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: wc.textSec,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '기도 나누기',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: wc.text,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: (_isLoading || !hasText) ? null : _handleSubmit,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: wc.accent,
                            ),
                          )
                        : Text(
                            '등록',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: hasText ? wc.accent : wc.textTer,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            // Body — 카드 없이 풀블리드 입력 영역. padding 최소화로 작성 공간 ↑
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _contentController,
                  focusNode: _focusNode,
                  maxLength: maxLen,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  cursorColor: wc.accent,
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.6,
                    color: wc.text,
                    letterSpacing: -0.2,
                  ),
                  decoration: InputDecoration(
                    hintText: '어떤 기도 제목이 있으신가요?\n편하게 나눠주세요.',
                    hintStyle: TextStyle(
                      color: wc.textTer,
                      fontSize: 17,
                      height: 1.6,
                    ),
                    border: InputBorder.none,
                    counterText: '',
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
              ),
            ),
            // Footer — 토글 + 카운터. 키보드 떠 있을 땐 한 줄로 압축
            _Footer(
              isAnonymous: _isAnonymous,
              compact: _focusNode.hasFocus,
              charCount: charCount,
              maxLen: maxLen,
              overLimit: overLimit,
              errorMessage: _errorMessage,
              onToggle: () {
                Haptic.selection();
                setState(() => _isAnonymous = !_isAnonymous);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.isAnonymous,
    required this.compact,
    required this.charCount,
    required this.maxLen,
    required this.overLimit,
    required this.errorMessage,
    required this.onToggle,
  });

  final bool isAnonymous;
  final bool compact;
  final int charCount;
  final int maxLen;
  final bool overLimit;
  final String? errorMessage;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(16, compact ? 4 : 8, 16, compact ? 6 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                errorMessage!,
                style: TextStyle(color: wc.danger, fontSize: 13),
              ),
            ),
          Row(
            children: [
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: compact
                      ? const EdgeInsets.fromLTRB(8, 5, 6, 5)
                      : const EdgeInsets.fromLTRB(14, 9, 10, 9),
                  decoration: BoxDecoration(
                    color: isAnonymous ? wc.anonBorder : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isAnonymous ? wc.anonBorder : wc.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FluentIcons.eye_off_16_regular,
                        size: 16,
                        color: isAnonymous ? wc.anonText : wc.textTer,
                      ),
                      // 압축 모드에선 텍스트 숨기고 아이콘 + 스위치만
                      if (!compact) ...[
                        const SizedBox(width: 8),
                        Text(
                          '익명으로 작성',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isAnonymous ? wc.anonText : wc.textSec,
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      _AnonSwitch(on: isAnonymous),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$charCount/$maxLen',
                style: TextStyle(
                  fontSize: 12,
                  color: overLimit ? wc.danger : wc.textTer,
                  fontFeatures: const [
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnonSwitch extends StatelessWidget {
  const _AnonSwitch({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 28,
      height: 16,
      decoration: BoxDecoration(
        color: on ? wc.anonText : wc.border,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 180),
            top: 2,
            left: on ? 14 : 2,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
