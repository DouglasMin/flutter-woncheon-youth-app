import 'package:dio/dio.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:woncheon_youth/core/api/api_error.dart';
import 'package:woncheon_youth/core/constants.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/shared/widgets/adaptive.dart';

class RegisterRequestPage extends StatefulWidget {
  const RegisterRequestPage({super.key});

  @override
  State<RegisterRequestPage> createState() => _RegisterRequestPageState();
}

class _RegisterRequestPageState extends State<RegisterRequestPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _success = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final note = _noteController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = '이름을 입력해주세요.');
      return;
    }
    if (phone.isEmpty) {
      setState(() => _errorMessage = '연락처를 입력해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Haptic.medium();

    try {
      final dio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));
      await dio.post<Map<String, dynamic>>(
        '/auth/register-request',
        data: {'name': name, 'phone': phone, 'note': note},
      );

      setState(() => _success = true);
      await Haptic.light();
    } on DioException catch (e) {
      await Haptic.heavy();
      setState(() {
        _errorMessage = getApiErrorMessage(e, fallback: '요청에 실패했습니다.');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_success) {
      return _buildSuccessScreen(context);
    }

    final body = SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FluentIcons.person_add_24_filled,
                size: 48,
                color: context.isDark ? AppColors.darkTextSecondary : AppColors.primaryDark,
              ),
              const SizedBox(height: 16),
              Text(
                '새신자 등록 요청',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '정보를 입력하시면 관리자 승인 후\n앱을 이용하실 수 있습니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: context.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              // Form
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: context.cardShadowColor,
                      blurRadius: 24,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AdaptiveTextField(
                      controller: _nameController,
                      placeholder: '이름 *',
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),
                    AdaptiveTextField(
                      controller: _phoneController,
                      placeholder: '연락처 (휴대폰 번호) *',
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),
                    AdaptiveTextField(
                      controller: _noteController,
                      placeholder: '하고 싶은 말 (선택)',
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleSubmit(),
                    ),

                    // Error
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      child: _errorMessage != null
                          ? Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withAlpha(15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 20),

                    AdaptiveButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      isLoading: _isLoading,
                      child: const Text(
                        '요청하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  '로그인으로 돌아가기',
                  style: TextStyle(color: context.textTertiary),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('새신자 등록'),
          backgroundColor: MediaQuery.platformBrightnessOf(context) == Brightness.dark
              ? AppTheme.cupertinoDark.barBackgroundColor
              : AppTheme.cupertinoLight.barBackgroundColor,
        ),
        child: Material(type: MaterialType.transparency, child: body),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('새신자 등록')),
      body: body,
    );
  }

  Widget _buildSuccessScreen(BuildContext context) {
    final content = SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  FluentIcons.checkmark_circle_24_filled,
                  size: 56,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '요청이 접수되었습니다!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '관리자가 승인하면\n로그인할 수 있습니다.',
                style: TextStyle(
                  fontSize: 15,
                  color: context.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              AdaptiveButton(
                onPressed: () => context.go('/login'),
                child: const Text(
                  '로그인으로 돌아가기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (isIOS) {
      return CupertinoPageScaffold(
        child: Material(type: MaterialType.transparency, child: content),
      );
    }

    return Scaffold(body: content);
  }
}
