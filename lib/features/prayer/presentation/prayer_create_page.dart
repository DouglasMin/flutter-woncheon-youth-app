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

class _PrayerCreatePageState extends ConsumerState<PrayerCreatePage>
    with SingleTickerProviderStateMixin {
  final _contentController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isAnonymous = false;
  bool _isLoading = false;
  String? _errorMessage;
  late final AnimationController _glowController;

  static const _bgColor = Color(0xFF0A0E2A);
  static const _goldAccent = Color(0xFFC9A96E);
  static const _goldLight = Color(0xFFD4B88A);

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _contentController.dispose();
    _focusNode.dispose();
    _glowController.dispose();
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
    final charCount = _contentController.text.length;
    const maxLen = AppConstants.maxPrayerContentLength;

    final submitButton = _isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _goldAccent,
            ),
          )
        : const Text(
            '등록',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: _goldAccent,
              fontSize: 16,
            ),
          );

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '기도 작성',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSubmit,
            child: submitButton,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Ambient glow — top right
          Positioned(
            top: -60,
            right: -60,
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, _) {
                return Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _goldAccent.withAlpha(
                          (12 + (_glowController.value * 10)).toInt(),
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Ambient glow — bottom left
          Positioned(
            bottom: -80,
            left: -40,
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, _) {
                return Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _goldAccent.withAlpha(
                          (8 + (_glowController.value * 6)).toInt(),
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Text area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: TextField(
                      controller: _contentController,
                      focusNode: _focusNode,
                      maxLength: maxLen,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        height: 1.8,
                        letterSpacing: 0.2,
                      ),
                      cursorColor: _goldAccent,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.transparent,
                        hintText: '오늘의 기도제목을 나눠주세요...',
                        hintStyle: TextStyle(
                          color: _goldLight.withAlpha(80),
                          fontSize: 17,
                          fontStyle: FontStyle.italic,
                          height: 1.8,
                        ),
                        border: InputBorder.none,
                        counterText: '',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),

                // Error
                if (_errorMessage != null)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFFC8181),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                // Bottom bar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withAlpha(10),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Anonymous toggle
                      GestureDetector(
                        onTap: () {
                          Haptic.selection();
                          setState(() => _isAnonymous = !_isAnonymous);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _isAnonymous
                                ? _goldAccent.withAlpha(25)
                                : Colors.white.withAlpha(8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isAnonymous
                                  ? _goldAccent.withAlpha(60)
                                  : Colors.white.withAlpha(15),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isAnonymous
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: 16,
                                color: _isAnonymous
                                    ? _goldAccent
                                    : Colors.white.withAlpha(100),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isAnonymous ? '익명' : '실명',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _isAnonymous
                                      ? _goldAccent
                                      : Colors.white.withAlpha(100),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Character count
                      Text(
                        '$charCount/$maxLen',
                        style: TextStyle(
                          fontSize: 12,
                          color: charCount > maxLen * 0.9
                              ? const Color(0xFFFC8181)
                              : Colors.white.withAlpha(60),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
