import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woncheon_youth/core/api/api_error.dart';
import 'package:woncheon_youth/core/mock/mock_auth_repository.dart';
import 'package:woncheon_youth/core/mock/mock_mode.dart';
import 'package:woncheon_youth/core/router/app_router.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/features/auth/presentation/auth_providers.dart';
import 'package:woncheon_youth/features/member/presentation/block_providers.dart';
import 'package:woncheon_youth/shared/widgets/adaptive.dart';
import 'package:woncheon_youth/shared/widgets/wc_widgets.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final name = _nameController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = '이름과 비밀번호를 입력해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Haptic.medium();

    try {
      late final Map<String, dynamic> data;
      if (kMockMode) {
        data = await ref
            .read(mockAuthRepositoryProvider)
            .login(name: name, password: password);
      } else {
        data = await ref
            .read(authRepositoryProvider)
            .login(name: name, password: password);
      }
      final isFirstLogin = data['isFirstLogin'] as bool? ?? false;

      if (!mounted) return;

      // 최신 차단 목록이 secure storage에 저장됐으므로 provider 재빌드 트리거
      ref.invalidate(blocklistProvider);

      if (isFirstLogin) {
        context.go(AppRoutes.changePassword);
      } else {
        context.go(AppRoutes.home);
      }
    } on MockApiException catch (e) {
      await Haptic.heavy();
      setState(() => _errorMessage = e.message);
    } on DioException catch (e) {
      await Haptic.heavy();
      setState(() {
        _errorMessage = getApiErrorMessage(e, fallback: '로그인에 실패했습니다.');
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
          padding: const EdgeInsets.fromLTRB(28, 60, 28, 24),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/woncheon_lgo.png',
                          width: 72,
                          height: 72,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '원천청년부',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: wc.text,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '함께 기도하고, 함께 성장해요',
                          style: TextStyle(
                            fontSize: 13,
                            color: wc.textSec,
                          ),
                        ),
                        const SizedBox(height: 42),
                        _field(
                          controller: _nameController,
                          focusNode: _nameFocus,
                          hint: '이름',
                          onSubmitted: (_) => _passwordFocus.requestFocus(),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 10),
                        _field(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          hint: '비밀번호',
                          obscureText: true,
                          onSubmitted: (_) => _handleLogin(),
                          textInputAction: TextInputAction.done,
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                fontSize: 13,
                                color: wc.danger,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        WCButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          disabled: _isLoading,
                          child: _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: wc.bg,
                                  ),
                                )
                              : const Text('로그인'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.registerRequest),
                child: Text.rich(
                  TextSpan(
                    text: '처음이신가요? ',
                    style: TextStyle(color: wc.textSec, fontSize: 14),
                    children: [
                      TextSpan(
                        text: '등록 요청하기',
                        style: TextStyle(
                          color: wc.text,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: wc.text,
                          decorationStyle: TextDecorationStyle.solid,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    bool obscureText = false,
    TextInputAction textInputAction = TextInputAction.next,
    ValueChanged<String>? onSubmitted,
  }) {
    final wc = context.wc;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: TextStyle(fontSize: 15, color: wc.text),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: wc.surface,
        hintStyle: TextStyle(color: wc.textTer, fontSize: 15),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: wc.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: wc.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: wc.accent, width: 1.5),
        ),
      ),
    );
  }
}
