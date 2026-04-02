import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woncheon_youth/core/api/api_error.dart';
import 'package:woncheon_youth/core/mock/mock_auth_repository.dart';
import 'package:woncheon_youth/core/mock/mock_mode.dart';
import 'package:woncheon_youth/core/push/push_providers.dart';
import 'package:woncheon_youth/core/router/app_router.dart';
import 'package:woncheon_youth/features/auth/presentation/auth_providers.dart';
import 'package:woncheon_youth/shared/providers/providers.dart';
import 'package:woncheon_youth/shared/widgets/adaptive.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleChange() async {
    final current = _currentController.text;
    final newPw = _newController.text;
    final confirm = _confirmController.text;

    if (current.isEmpty || newPw.isEmpty || confirm.isEmpty) {
      setState(() => _errorMessage = '모든 항목을 입력해주세요.');
      return;
    }

    if (newPw.length < 8) {
      setState(() => _errorMessage = '8자 이상 입력해주세요.');
      return;
    }

    if (newPw != confirm) {
      setState(() => _errorMessage = '새 비밀번호가 일치하지 않습니다.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Haptic.medium();

    try {
      if (kMockMode) {
        final mockRepo = ref.read(mockAuthRepositoryProvider);
        await mockRepo.changePassword(
          currentPassword: current,
          newPassword: newPw,
        );
      } else {
        final authRepo = ref.read(authRepositoryProvider);
        await authRepo.changePassword(
          currentPassword: current,
          newPassword: newPw,
        );
      }

      if (!mounted) return;
      unawaited(Haptic.light());

      // Request notification permission after first password change
      await _requestPushPermission();

      if (!mounted) return;
      context.go(AppRoutes.home);
    } on MockApiException catch (e) {
      await Haptic.heavy();
      setState(() => _errorMessage = e.message);
    } on DioException catch (e) {
      await Haptic.heavy();
      setState(() {
        _errorMessage = getApiErrorMessage(e, fallback: '비밀번호 변경에 실패했습니다.');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _requestPushPermission() async {
    final pushService = ref.read(pushNotificationServiceProvider);
    final granted = await pushService.requestPermission();

    if (!granted) return;

    // Listen for token and register with server
    final tokenSub = pushService.onTokenReceived.listen((token) async {
      try {
        final apiClient = ref.read(apiClientProvider);
        await apiClient.dio.post<Map<String, dynamic>>(
          '/auth/device-token',
          data: {'token': token, 'platform': 'ios'},
        );
      } catch (e) {
        debugPrint('Failed to register device token: $e');
      }
    });

    // Clean up after a short delay (token arrives quickly)
    Future<void>.delayed(const Duration(seconds: 10), tokenSub.cancel);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: isIOS
          ? null
          : AppBar(title: const Text('비밀번호 변경'), centerTitle: true),
      body: isIOS
          ? CupertinoPageScaffold(
              navigationBar: const CupertinoNavigationBar(
                middle: Text('비밀번호 변경'),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: _buildBody(theme),
              ),
            )
          : _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                FluentIcons.shield_lock_24_filled,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                '첫 로그인 시\n비밀번호를 변경해주세요',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              AdaptiveTextField(
                controller: _currentController,
                placeholder: '현재 비밀번호',
                obscureText: true,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AdaptiveTextField(
                controller: _newController,
                placeholder: '새 비밀번호 (8자 이상)',
                obscureText: true,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AdaptiveTextField(
                controller: _confirmController,
                placeholder: '새 비밀번호 확인',
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleChange(),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _errorMessage != null
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 28),
              AdaptiveButton(
                onPressed: _isLoading ? null : _handleChange,
                isLoading: _isLoading,
                child: const Text(
                  '변경하기',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
