import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woncheon_youth/core/api/api_error.dart';
import 'package:woncheon_youth/core/mock/mock_auth_repository.dart';
import 'package:woncheon_youth/core/mock/mock_mode.dart';
import 'package:woncheon_youth/core/push/push_token_registrar.dart';
import 'package:woncheon_youth/core/router/app_router.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/features/auth/presentation/auth_providers.dart';
import 'package:woncheon_youth/shared/widgets/adaptive.dart';
import 'package:woncheon_youth/shared/widgets/wc_widgets.dart';

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

  bool get _valid =>
      _newController.text.length >= 8 &&
      _newController.text == _confirmController.text;

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
        await ref.read(mockAuthRepositoryProvider).changePassword(
              currentPassword: current,
              newPassword: newPw,
            );
      } else {
        await ref.read(authRepositoryProvider).changePassword(
              currentPassword: current,
              newPassword: newPw,
            );
      }

      if (!mounted) return;
      unawaited(Haptic.light());
      unawaited(registerDeviceTokenAfterAuth(ref));
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

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    return Scaffold(
      backgroundColor: wc.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IconButton(
                onPressed: () => context.pop(),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                icon: Icon(FluentIcons.chevron_left_24_regular,
                    color: wc.textSec, size: 26),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: wc.accentSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    FluentIcons.lock_closed_24_regular,
                    size: 22,
                    color: wc.accentInk,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '새 비밀번호를\n설정해주세요',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: wc.text,
                  letterSpacing: -0.5,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '보안을 위해 처음 로그인 시에는\n비밀번호 변경이 필요합니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: wc.textSec,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 30),
              _field(
                controller: _currentController,
                hint: '현재 비밀번호',
                obscure: true,
                action: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              _field(
                controller: _newController,
                hint: '새 비밀번호 (8자 이상)',
                obscure: true,
                action: TextInputAction.next,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              _field(
                controller: _confirmController,
                hint: '비밀번호 확인',
                obscure: true,
                action: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _handleChange(),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: wc.danger, fontSize: 12),
                ),
              ],
              const Spacer(),
              WCButton(
                onPressed: (_isLoading || !_valid) ? null : _handleChange,
                disabled: _isLoading || !_valid,
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: wc.bg,
                        ),
                      )
                    : const Text('변경하고 시작하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputAction action = TextInputAction.next,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
  }) {
    final wc = context.wc;
    return TextField(
      controller: controller,
      obscureText: obscure,
      textInputAction: action,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: TextStyle(color: wc.text, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: wc.surface,
        hintStyle: TextStyle(color: wc.textTer, fontSize: 15),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: wc.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: wc.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: wc.accent, width: 1.5),
        ),
      ),
    );
  }
}
